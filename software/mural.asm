;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/mural/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
mural:
	; utwórz okno
	mov	rsi,	mural_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu
	jc	mural.end	; brak wystarczającej przestrzeni pamięci

	; wyświetl zawartość okna
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	mural_window
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

	; debug
	jmp	$

.end:
	; zakończ pracę programu
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: mural"

	;-----------------------------------------------------------------------
	%include	"software/mural/data.asm"
	;-----------------------------------------------------------------------
