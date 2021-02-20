;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - pozostały czas do przesunięcia klocka
; wejście:
;	dx - kod klawisza
taris_keyboard:
	; naciśnięto klawisze LEFT ARROW
	cmp	dx,	STATIC_SCANCODE_LEFT
	jne	.no_left	; nie

	; przesuń blok o pozycję w lewo
	dec	r9

	; sprawdź czy blok koliduje z aktualnie istniejącymi
	call	taris_collision
	jz	.redraw	; brak kolizji

	; cofnij przesunięcie
	inc	r9

	; koniec obsługi klawisza
	jmp	.done

.no_left:
	; naciśnięto klawisze RIGHT ARROW
	cmp	dx,	STATIC_SCANCODE_RIGHT
	jne	.no_right	; nie

	; przesuń blok o pozycję w lewo
	inc	r9

	; sprawdź czy blok koliduje z aktualnie istniejącymi
	call	taris_collision
	jz	.redraw	; brak kolizji

	; cofnij przesunięcie
	dec	r9

	; koniec obsługi klawisza
	jmp	.done

.no_right:
	; naciśnięto klawisz Z
	cmp	dx,	"z"
	jne	.no_z	; nie

	; obróć blok w lewo
	rol	rbx,	STATIC_MOVE_HIGH_TO_AX_shift

	; sprawdź czy blok koliduje z aktualnie istniejącymi
	call	taris_collision
	jz	.redraw	; brak kolizji

	; cofnij obrót
	ror	rbx,	STATIC_MOVE_AX_TO_HIGH_shift

	; koniec obsługi klawisza
	jmp	.done

.no_z:
	; naciśnięto klawisz X
	cmp	dx,	"x"
	jne	.no_x	; nie

	; obróć blok w prawo
	ror	rbx,	STATIC_MOVE_HIGH_TO_AX_shift

	; sprawdź czy blok koliduje z aktualnie istniejącymi
	call	taris_collision
	jz	.redraw	; brak kolizji

	; cofnij obrót
	rol	rbx,	STATIC_MOVE_AX_TO_HIGH_shift

	; koniec obsługi klawisza
	jmp	.done

.no_x:
	; naciśnięto klawisze ARROW DOWN
	cmp	dx,	STATIC_SCANCODE_DOWN
	jne	.no_down	; nie

	; zmień szybkość przemieszczania bloku
	push	qword [taris_microtime_softdrop]
	pop	qword [taris_microtime]

	; zacznij od zaraz
	stc

	; koniec obsługi klawisza
	jmp	.end

.no_down:
	; naciśnięto klawisze ARROW UP
	cmp	dx,	STATIC_SCANCODE_UP
	jne	.done	; nie

.space_loop:
	; przesuń blok o wiersz w dół
	inc	r10

	; sprawdź czy blok koliduje z aktualnie istniejącymi
	call	taris_collision
	jz	.space_loop	; brak kolizji

	; skoryguj pozycję bloku
	dec	r10

	; flaga, odłóż blok
	stc

	; koniec obsługi klawisza
	jmp	.end

.redraw:
	; wyświetl aktualny stan gry
	call	taris_redraw

.done:
	; wyczyść zarezerwowaną Flagę CF
	clc

.end:
	; powrót z procedury
	ret
