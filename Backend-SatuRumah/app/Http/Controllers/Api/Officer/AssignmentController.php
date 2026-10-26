<?php

namespace App\Http\Controllers\Api\Officer;

use App\Http\Controllers\Api\Concerns\RespondsWithErrors;
use App\Http\Controllers\Controller;
use App\Models\InspectionAssignment;
use App\Services\ReportPresenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Tugas survei milik petugas yang masuk (tugas orang lain → 404). */
class AssignmentController extends Controller
{
    use RespondsWithErrors;

    public function __construct(private readonly ReportPresenter $presenter)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $request->validate(['status' => ['nullable', 'in:open,all,dijadwalkan,diterima,selesai,dialihkan,dibatalkan']]);
        $status = $request->input('status', 'open');

        $items = InspectionAssignment::query()
            ->where('officer_id', $request->user()->id)
            ->with('submission.developer.developerProfile')
            ->when($status === 'open', fn ($q) => $q->whereIn('status', InspectionAssignment::OPEN))
            ->when(!in_array($status, ['open', 'all'], true), fn ($q) => $q->where('status', $status))
            ->orderBy('scheduled_date')
            ->orderBy('id')
            ->get();

        return response()->json(['data' => $items->map(fn ($a) => $this->presenter->assignment($a))->all()]);
    }

    public function accept(Request $request, int $id): JsonResponse
    {
        $assignment = InspectionAssignment::where('officer_id', $request->user()->id)
            ->with('submission.developer.developerProfile')
            ->findOrFail($id);

        if ($assignment->status === 'dijadwalkan') {
            $assignment->forceFill(['status' => 'diterima', 'accepted_at' => now()])->save();
        } elseif ($assignment->status !== 'diterima') {
            return $this->error('ERR-011', 'Tugas ini tidak dapat diterima pada status sekarang.', 409);
        }

        return response()->json(['data' => $this->presenter->assignment($assignment)]);
    }
}
