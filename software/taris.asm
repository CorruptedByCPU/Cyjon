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
	; inicjalizuj środowisko pracy
	%include	"software/taris/init.asm"

.init:
	; wylosuj blok i jego model
	call	taris_random_block

	; startowa pozycja bloku
	mov	r9,	TARIS_BRICK_START_POSITION_x
	mov	r10,	TARIS_BRICK_START_POSITION_y

.loop:
	; sprawdź czy nowy blok koliduje z aktualnie istniejącymi
	call	taris_collision

	; wyczyść przestrzeń roboczą
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_clear

	; wyświetl blok na nowej pozycji
	call	taris_show_block

	; synchronizacja zawartości z przestrzenią roboczą
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_flush

	; aktualizuj zawartość okna
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	taris_window
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

	; czekaj na reakcję gracza
	call	taris_wait

	; przesuń blok o jeden poziom w dół
	inc	r10

	; kontnuuj
	jmp	.init	; debug

.close:
	; zakończ pracę programu
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: taris"

	;-----------------------------------------------------------------------
	%include	"software/taris/data.asm"
	%include	"software/taris/random.asm"
	%include	"software/taris/collision.asm"
	%include	"software/taris/wait.asm"
	%include	"software/taris/show.asm"
	;-----------------------------------------------------------------------
