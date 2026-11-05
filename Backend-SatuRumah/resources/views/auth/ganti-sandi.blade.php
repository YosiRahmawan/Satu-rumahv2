@extends('layouts.portal')

@section('title', 'Ganti Sandi - SATU RUMAH')

@section('content')
<div class="hero">
    <div>
        <div class="hero-crumbs"><b>Akun</b></div>
        <div class="hero-title">Ganti Sandi</div>
        <div class="hero-sub">{{ auth()->user()->must_change_password ? 'Sandi Anda masih sementara. Ganti dulu sebelum memakai portal.' : 'Gunakan sandi yang kuat dan tidak dipakai di tempat lain.' }}</div>
    </div>
</div>

@include('auth._form-sandi')
@endsection

@section('scripts')
@include('auth._script-sandi')
@endsection
