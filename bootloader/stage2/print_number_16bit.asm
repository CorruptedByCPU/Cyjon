;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 16 Bitowy kod programu
[BITS 16]

stage2_print_number_16bit:
	; zachowaj oryginalne rejestry
	push	ax
	push	cx
	push	dx
	push	sp
	push	bp

	; system heksadecymalny
	mov	cx,	16

	; wyczść resztę/ starszą część
	xor	dx,	dx

	; zapamiętaj koniec bufora danych
	mov	bp,	sp

.calculate:
	; podziel dx:ax przez cx
	div	cx

	; odstaw resztę z dzielenia do bufora
	push	dx

	; wyczść resztę/ starszą część
	xor	dx,	dx

	; sprawdź czy zostało jeszcze coś do przeliczenia
	cmp	ax,	VARIABLE_EMPTY
	jne	.calculate	; jeśli tak, powtórz operacje

.print:
	; pobierz z bufora najstarszą cyfre
	pop	ax

	; procedura - wyświetl znak w miejscu kursora, przesuń kursor w prawo
	mov	ah,	0x0E

	; sprawdź czy znak spoza cyfr
	cmp	al,	0x0A
	jb	.digit

	; zamień cyfre na kod ASCII (A..F)
	add	al,	0x3A

	; kontynuuj
	jmp	.continue

.digit:
	; zamień cyfre na kod ASCII (0..9)
	add	al,	0x30	

.continue:
	; wyświetl cyfre na ekranie
	int	0x10

	; sprawdź czy zostało coś jeszcze w buforze
	cmp	bp,	sp
	jne	.print	; jeśli tak, kontynuuj

	; przywróć oryginalne rejestry
	pop	bp
	pop	sp
	pop	dx
	pop	cx
	pop	ax

	; powrót z procedury
	ret
