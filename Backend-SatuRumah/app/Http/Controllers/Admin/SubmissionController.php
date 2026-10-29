<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\InspectionAssignment;
use App\Models\InspectionReport;
use App\Models\InspectionReportPhoto;
use App\Models\ReportSignature;
use App\Services\SignatureService;
use App\Models\Submission;
use App\Models\User;
use App\Services\SubmissionWorkflow;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

/** Antrean dan tindakan admin. Semua perpindahan tahap lewat SubmissionWorkflow. */
class SubmissionController extends Controller
{
    public function __construct(private readonly SubmissionWorkflow $workflow)
    {
    }

    public function index(Request $request)
    {
        $base = Submission::where('stage', '>=', Submission::STAGE_ADMINISTRASI);

        $totals = [
            'semua' => (clone $base)->count(),
            'aktif' => (clone $base)->where('stage', '<', Submission::STAGE_SELESAI)->where('sub_status', '!=', 'ditolak')->count(),
            'menunggu' => (clone $base)->whereIn('sub_status', ['baru', 'perbaikan_terkirim'])->count(),
            'perbaikan' => (clone $base)->where('sub_status', 'perlu_perbaikan')->count(),
        ];

        $pengajuans = (clone $base)->with('developer.developerProfile')
            ->when($request->query('search'), function ($q, $term) {
                $q->where(fn ($w) => $w->where('number', 'like', "%{$term}%")
                    ->orWhere('nama_perumahan', 'like', "%{$term}%")
                    ->orWhereHas('developer.developerProfile', fn ($d) => $d->where('nama_pt', 'like', "%{$term}%")));
            })
            ->when($request->query('tahap'), fn ($q, $v) => $q->where('stage', (int) $v))
            ->when($request->query('status'), fn ($q, $v) => $q->where('sub_status', $v))
            ->latest('updated_at')->paginate(15)->withQueryString();

        return view('admin.pengajuan.index', compact('pengajuans', 'totals'));
    }

    public function show(Request $request, int $id)
    {
        $s = Submission::with(['developer.developerProfile', 'currentFiles', 'events.actor', 'assignments.officer', 'assignments.members', 'reports.photos', 'reports.officer'])
            ->where('stage', '>=', Submission::STAGE_ADMINISTRASI)->findOrFail($id);

        $tab = in_array($request->query('tab'), ['dokumen', 'monitoring', 'riwayat'], true) ? $request->query('tab') : 'ringkasan';

        return view('admin.pengajuan.show', [
            's' => $s,
            'tab' => $tab,
            'slots' => $this->workflow->slots(),
            'filesBySlot' => $s->currentFiles->groupBy('slot_code'),
            'officers' => User::where('role', 'tim_lapangan')->where('is_active', true)->orderBy('name')->get(),
        ]);
    }

    public function file(int $id, int $fileId)
    {
        $file = Submission::findOrFail($id)->files()->findOrFail($fileId);
        abort_unless(Storage::disk('local')->exists($file->storage_path), 404);

        return Storage::disk('local')->download($file->storage_path, $file->original_name);
    }

    /** Menampilkan PDF di dalam halaman (pratinjau), tanpa memaksa unduh. */
    public function lihat(int $id, int $fileId)
    {
        $file = Submission::findOrFail($id)->files()->findOrFail($fileId);
        abort_unless($file->file_type === 'pdf' && Storage::disk('local')->exists($file->storage_path), 404);

        return Storage::disk('local')->response($file->storage_path, $file->original_name, [
            'Content-Type' => 'application/pdf',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    public function photo(int $id, int $photoId)
    {
        $photo = InspectionReportPhoto::whereHas('report', fn ($q) => $q->where('submission_id', $id))->findOrFail($photoId);
        abort_unless(Storage::disk('local')->exists($photo->storage_path), 404);

        return Storage::disk('local')->response($photo->storage_path, "foto-{$photo->position}.jpg");
    }

    public function review(Request $request, int $id, int $fileId)
    {
        $data = $request->validate(['decision' => 'required|in:lolos,perlu_perbaikan', 'catatan' => 'nullable|string|max:1000']);
        $s = Submission::findOrFail($id);

        return $this->run($s, fn () => $this->workflow->reviewFile(
            $s, $s->files()->findOrFail($fileId), $data['decision'], $data['catatan'] ?? null, $request->user()
        ), 'Penilaian berkas disimpan.', 'dokumen');
    }

    public function requestRevision(Request $request, int $id)
    {
        $s = Submission::findOrFail($id);

        return $this->run($s, fn () => $this->workflow->requestRevision($s, $request->user()), 'Permintaan perbaikan dikirim ke pengembang.', 'dokumen');
    }

    public function approve(Request $request, int $id)
    {
        $s = Submission::findOrFail($id);

        return $this->run($s, fn () => $this->workflow->approveAdministration($s, $request->user()), 'Verifikasi administrasi disetujui.', 'ringkasan');
    }

    public function schedule(Request $request, int $id)
    {
        $data = $request->validate([
            'petugas_id' => 'required|integer',
            'tanggal' => 'required|date|after_or_equal:today',
            'catatan' => 'nullable|string|max:500',
            'alasan' => 'nullable|string|max:300',
            'anggota' => 'nullable|array|max:9',
            'anggota.*' => 'integer',
        ]);
        $s = Submission::findOrFail($id);
        $officer = User::findOrFail($data['petugas_id']);

        return $this->run($s, fn () => $this->workflow->scheduleSurvey(
            $s, $officer, $data['tanggal'], $data['catatan'] ?? null, $request->user(), $data['alasan'] ?? null, $data['anggota'] ?? []
        ), 'Jadwal survei disimpan dan petugas diberi tahu.', 'monitoring');
    }

    public function cancelAssignment(Request $request, int $id, int $assignmentId)
    {
        $data = $request->validate(['alasan' => 'required|string|max:300']);
        $s = Submission::findOrFail($id);
        $a = InspectionAssignment::where('submission_id', $id)->findOrFail($assignmentId);

        return $this->run($s, fn () => $this->workflow->cancelAssignment($s, $a, $request->user(), $data['alasan']), 'Penugasan dibatalkan dan petugas diberi tahu.', 'monitoring');
    }

    public function publishReport(Request $request, int $id, int $reportId)
    {
        $s = Submission::findOrFail($id);
        $r = InspectionReport::where('submission_id', $id)->findOrFail($reportId);

        return $this->run($s, fn () => $this->workflow->publishReport($s, $r, $request->user()), 'BA diterbitkan.', 'monitoring');
    }

    public function signReport(Request $request, int $id, int $reportId, SignatureService $signatures)
    {
        $data = $request->validate([
            'method' => 'required|in:draw,upload',
            'password' => 'required|string',
            'version' => 'required|integer',
        ]);
        $s = Submission::findOrFail($id);
        $r = InspectionReport::where('submission_id', $id)->findOrFail($reportId);

        try {
            $bytes = $signatures->bytesFrom($request);
        } catch (ValidationException $e) {
            return redirect()->route('pengajuan.show', ['id' => $id, 'tab' => 'monitoring'])->withErrors($e->errors());
        }

        return $this->run($s, fn () => $signatures->sign($r, $request->user(), ReportSignature::ADMIN, $data['method'], $bytes, $data['password'], (int) $data['version'], $request->ip()), 'Tanda tangan Admin tersimpan.', 'monitoring');
    }

    public function reportPdf(int $id, int $reportId)
    {
        $r = InspectionReport::where('submission_id', $id)->findOrFail($reportId);
        abort_unless($r->published_at && $r->pdf_path && Storage::disk('local')->exists($r->pdf_path), 404);

        return Storage::disk('local')->download($r->pdf_path, 'BA-' . str_replace('/', '-', (string) $r->report_number) . '.pdf');
    }

    public function acceptReports(Request $request, int $id)
    {
        $s = Submission::findOrFail($id);

        return $this->run($s, fn () => $this->workflow->acceptReports($s, $request->user()), 'Laporan survei diterima. Lanjut ke persetujuan.', 'monitoring');
    }

    public function decide(Request $request, int $id)
    {
        $data = $request->validate([
            'keputusan' => 'required|in:setuju,tolak',
            'nomor' => 'nullable|string|max:100',
            'tanggal' => 'nullable|date',
            'catatan' => 'nullable|string|max:1000',
        ]);
        $s = Submission::findOrFail($id);

        return $this->run($s, fn () => $this->workflow->decide(
            $s, $data['keputusan'] === 'setuju', $data['nomor'] ?? null, $data['tanggal'] ?? null, $data['catatan'] ?? null, $request->user()
        ), 'Keputusan akhir disimpan.', 'ringkasan');
    }

    /** Menjalankan aksi workflow; galat aturan ditampilkan sebagai pesan, bukan 500. */
    private function run(Submission $s, \Closure $action, string $ok, string $tab)
    {
        $back = redirect()->route('pengajuan.show', ['id' => $s->id, 'tab' => $tab]);

        try {
            $action();
        } catch (ValidationException $e) {
            return $back->withErrors($e->errors())->withInput();
        } catch (\DomainException $e) {
            return $back->with('warning', $e->getMessage());
        }

        return $back->with('success', $ok);
    }
}
