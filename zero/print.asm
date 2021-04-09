;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; 16 bitowy kod
;===============================================================================
[bits 16]

;===============================================================================
; wejście:
;	al - znak ASCII
zero_print_char:
	; zachowaj oryginalne rejestry
	push	ax

	; wyświetl znak na ekranie
	mov	ah,	0x0E
	int	0x10

	; przywróć oryginalne rejestry
	pop	ax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	si - wskaźnik do ciągu znaków zakończony terminatorem 0x00
zero_print_string:
	; zachowaj oryginalne rejestry
	push	ax
	push	si

.loop:
	; pobierz do AL wartość z adresu pod wskaźnikiem SI, zwiększ wskaźnik SI o 1
	lodsb

	; sprawdź czy koniec tekstu do wyświetlenia
	cmp	al,	0x00	; jeśli ZERO, zakończ
	je	.end

	; wyświetl znak na ekranie
	call	zero_print_char

	; załaduj i wyświetl następny znak
	jmp	.loop

.end:
	; przywróć oryginalne rejestry
	pop	si
	pop	ax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	ax - wartość do wyświetlenia
zero_print_number:
	; zachowaj oryginalne rejestry
	push	ax
	push	cx
	push	dx
	push	sp
	push	bp

	; system dziesiętny
	mov	cx,	10

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

	; sprawdź czy zostało jeszcze coś do przeliczenia
	cmp	ax,	0x0000
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
