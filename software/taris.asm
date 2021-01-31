;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/taris/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
taris:
	; utwórz okno
	mov	rsi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu
	jc	taris.close	; brak wystarczającej przestrzeni pamięci

.loop:
	; wylosuj blok
	call	taris_random

	; sprawdź przychodzące zdarzenia
	mov	rsi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_event
	jc	.loop	; brak wyjątku związanego z klawiaturą

	; cdn.
	jmp	.loop

.close:
	; zakończ pracę programu
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: taris"

	;-----------------------------------------------------------------------
	%include	"software/taris/data.asm"
	%include	"software/taris/random.asm"
	;-----------------------------------------------------------------------
