<script>
    const EYE = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>';
    const EYE_OFF = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3l18 18M10.6 10.6a3 3 0 004.2 4.2M9.9 5.1A9.8 9.8 0 0112 5c4.5 0 8.3 2.9 9.5 7a10 10 0 01-2.6 4.2M6.2 6.2A10 10 0 002.5 12c1.2 4.1 5 7 9.5 7a9.700 9.700 0 003.8-.8"/>';
    document.querySelectorAll('.pw-toggle').forEach(b => b.addEventListener('click', () => {
        const input = b.parentElement.querySelector('input');
        const tampil = input.type === 'password';
        input.type = tampil ? 'text' : 'password';
        b.querySelector('svg').innerHTML = tampil ? EYE_OFF : EYE;
    }));
</script>
