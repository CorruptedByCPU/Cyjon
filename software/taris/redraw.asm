;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
taris_redraw:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; ustaw wskaźnik na właściwości przestrzeni gry
	mov	r8,	taris_rgl_foresee_properties

	; wyczyść przestrzeń roboczą
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_clear

	; wyświetl następny klocek
	call	taris_show_foresee

	; synchronizacja zawartości z przestrzenią roboczą
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_flush

	; ustaw wskaźnik na właściwości przestrzeni gry
	mov	r8,	taris_rgl_playground_properties

	; wyczyść przestrzeń roboczą
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_clear

	; wyświetl przestrzeń gry
	call	taris_show_playground

	; wyświetl blok na nowej pozycji
	call	taris_show_block

	; synchronizacja zawartości z przestrzenią roboczą
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_flush

	; aktualizuj zawartość okna
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	taris_window
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z podprocedury
	ret
