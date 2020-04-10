;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	; pobierz informacje o ekranie
	mov	ax,	KERNEL_SERVICE_VIDEO_properties
	int	KERNEL_SERVICE

	; pozycjonuj okno na środku ekranu
	shr	r8,	STATIC_DIVIDE_BY_2_shift
	shr	r9,	STATIC_DIVIDE_BY_2_shift

	; względem rozmiaru okna w poziomie
	mov	rax,	qword [console_window + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	shr	rax,	STATIC_DIVIDE_BY_2_shift
	sub	r8,	rax
	mov	qword [console_window + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	r8

	; względem rozmiaru okna w pionie
	mov	rax,	qword [console_window + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	shr	rax,	STATIC_DIVIDE_BY_2_shift
	sub	r9,	rax
	mov	qword [console_window + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	r9

	; utwórz okno
	mov	rsi,	console_window
	call	library_bosu

	; wyczyść przestrzeń elementu "draw_0"
	call	console_clear

	;-----------------------------------------------------------------------

	; wyświetl okno
	mov	al,	SERVICE_DESU_WINDOW_update
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	SERVICE_DESU_IRQ
