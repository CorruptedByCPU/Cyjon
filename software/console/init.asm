;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	; utwórz okno
	mov	rsi,	console_window
	call	library_bosu

	; wyświetl okno
	mov	al,	SERVICE_DESU_WINDOW_flags
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	SERVICE_DESU_IRQ
