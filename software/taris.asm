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
	; sprawdź czy blok koliduje z aktualnie istniejącymi
	call	taris_collision
	jnz	.check	; wystąpiła kolizja obiektów

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

	; czekaj na reakcję gracza
	call	taris_wait

	; przesuń blok o jeden poziom w dół
	inc	r10

	; kontnuuj
	jmp	.loop	; debug

.check:
	; kolizja wystąpiła na pozycji startowej?
	cmp	r9,	TARIS_BRICK_START_POSITION_x
	jne	.not_begin	; nie
	test	r10,	r10
	jz	.end	; tak

.not_begin:
	; cofnij blok na oryginalną pozycję
	dec	r10

	; scal blok z przestrzenią gry
	call	taris_inject

	; powrót do głównej pętli gry
	jmp	.init

.end:
	; debug
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
	%include	"software/taris/wait.asm"
	%include	"software/taris/show.asm"
	%include	"software/taris/inject.asm"
	;-----------------------------------------------------------------------
