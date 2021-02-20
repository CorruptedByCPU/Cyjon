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

.next:
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
	je	.game_over	; tak

.not_begin:
	; cofnij blok na oryginalną pozycję
	dec	r10

	; scal blok z przestrzenią gry
	call	taris_merge

	; sprawdź czy przyznać punkty
	call	taris_points
	jnc	.next	; powrót do głównej pętli gry

.game_over:
	; wyświetl etykietę "Game Over"
	mov	rsi,	taris_window.element_label_game_over
	mov	rdi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_element_label

	; aktualizuj zawartość okna
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	rdi
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

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
	%include	"software/taris/collision.asm"
	%include	"software/taris/data.asm"
	%include	"software/taris/interface.asm"
	%include	"software/taris/keyboard.asm"
	%include	"software/taris/level.asm"
	%include	"software/taris/merge.asm"
	%include	"software/taris/points.asm"
	%include	"software/taris/random.asm"
	%include	"software/taris/redraw.asm"
	%include	"software/taris/show.asm"
	%include	"software/taris/wait.asm"
	;-----------------------------------------------------------------------
