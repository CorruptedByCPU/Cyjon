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

	; wylosuj blok i jego model
	call	taris_random_block

	; startowa pozycja bloku
	mov	r8,	TARIS_BRICK_START_POSITION_x
	mov	r9,	TARIS_BRICK_START_POSITION_y

.loop:
	; sprawdź czy nowy blok koliduje z aktualnie istniejącymi
	call	taris_collision

	; sprawdź przychodzące zdarzenia
	mov	rsi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_event

	; cdn.
	jmp	$

.close:
	; zakończ pracę programu
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: taris"

	;-----------------------------------------------------------------------
	%include	"software/taris/data.asm"
	%include	"software/taris/random.asm"
	%include	"software/taris/collision.asm"
	;-----------------------------------------------------------------------
