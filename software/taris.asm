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

.restart:
	; wyczyść przestrzeń gry
	call	taris_show_empty

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

	; wyświetl aktualny stan gry
	call	taris_redraw

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
	cmp	r10,	TARIS_BRICK_START_POSITION_y
	je	.end	; tak

.not_begin:
	; cofnij blok na oryginalną pozycję
	dec	r10

	; scal blok z przestrzenią gry
	call	taris_inject

	; powrót do głównej pętli gry
	jmp	.init

.end:
	; sprawdź przychodzące zdarzenia
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_event
	jc	.end	; brak wyjątku

	; naciśnięto klawisz ESC?
	cmp	dx,	STATIC_SCANCODE_ESCAPE
	jne	.end	; nie

	; debug
	jmp	.restart

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
	%include	"software/taris/keyboard.asm"
	%include	"software/taris/redraw.asm"
	;-----------------------------------------------------------------------
