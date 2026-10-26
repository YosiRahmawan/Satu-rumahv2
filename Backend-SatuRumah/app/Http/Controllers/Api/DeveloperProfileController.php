<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeveloperProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class DeveloperProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json(['data' => DeveloperProfile::where('user_id', $request->user()->id)->first()]);
    }

    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = $request->validate([
            'nib' => ['required', 'digits:13', Rule::unique('developer_profiles', 'nib')->ignore(DeveloperProfile::where('user_id', $user->id)->value('id'))],
            'nama_perumahan' => ['required', 'string', 'max:150'],
            'nama_pt' => ['required', 'string', 'max:150'],
            'nama_direktur' => ['required', 'string', 'max:150'],
            'alamat_perumahan' => ['required', 'string', 'max:500'],
            'alamat_pt' => ['required', 'string', 'max:500'],
            'no_hp_direktur' => ['required', 'string', 'max:20'],
            'email_pt' => ['required', 'email', 'max:255'],
            'tipe_pengajuan' => ['required', 'string', 'max:30'],
        ]);

        $profile = DeveloperProfile::updateOrCreate(['user_id' => $user->id], $data);

        return response()->json(['data' => $profile]);
    }
}
