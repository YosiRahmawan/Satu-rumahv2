@echo off
rem Menjalankan penjadwal Laravel (pengingat tenggat perbaikan dan SLA, tiap hari 08.00).
rem Biarkan jendela ini terbuka bersama server (artisan serve).
cd /d "%~dp0"
set PHP=C:\laragon\bin\php\php-8.2.21-nts-Win32-vs16-x64\php.exe
"%PHP%" artisan schedule:work
