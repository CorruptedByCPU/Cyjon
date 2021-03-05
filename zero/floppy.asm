;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	cl - numer sektora
;	es:bx - miejsce docelowe
;	di - ilość sektorów
; wyjście:
;	Flaga CF - jeśli błąd
zero_floppy:
	; zachowaj oryginalne rejestry
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	bp
	push	es

	; czytaj po jednym sektorze na raz
	mov	al,	0x01	; ładuj po jednym sektorze na raz
	mov	ch,	0x00	; pierwszy cylinder
	mov	dh,	0x00	; pierwsza głowica

.reload:
	; ilość prób odczytu sektora z nośnika
	mov	bp,	0x03

.loop:
	; załaduj pierwszy sektor do pamięci
	mov	ah,	0x02
	int	0x13
	jc	.reset	; nie udało się odczytać sektora, zresetuj kontroler

	; odczytać kolejne sektory z nośnika?
	dec	di
	jz	.end	; nie

	; załaduj kolejny sektor
	inc	cl

	; na następną pozycję
	add	bx,	0x0200

	; to był ostatni sektor cylindra?
	cmp	cl,	18
	jbe	.reload	; nie

	; "druga" głowica
	not	dh
	and	dh,	00000001b

	; pierwszy sektor
	mov	cl,	1

	; obsłużono obydwie głowice?
	test	dh,	dh
	jnz	.reload	; nie

	; następnego cylindra
	inc	ch

	; to był ostatni cylinder głowicy?
	cmp	ch,	80
	jb	.reload	; nie

	; flaga, błąd
	stc

	; koniec procedury
	jmp	.end

.reset:
	; pierwsza nieudana próba
	mov	ah,	0x00	; zresetuj kontroler
	int	0x13
	jnc	.loop	; bez błędów, ponów odczyt sektora

.end:
	; przywróć oryginalne rejestry
	pop	es
	pop	bp
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	; powrót z procedury
	ret
