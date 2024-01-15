;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 64 bitowy kod programu
[BITS 64]

;===============================================================================
; procedura przetwarza ciąg cyfr z ASCII na wartość heksadecymalną
; IN:
;	rbx - system liczbowy
;	rcx - rozmiar liczby w znakach
;	rdi - wskaźnik do ciągu cyfr
; OUT:
;	CF  - 0 jeśli, ok
;	rax - liczba w postaci heksadecymalnej
;
; pozostałe rejestry zachowane
library_string_to_number:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi
	push	r8
	push	r9

	; przesuń wskaźnik na ostatnią cyfrę
	add	rdi,	rcx
	dec	rdi

	; system liczbowy
	mov	r9,	rbx

	; wyczyść wynik i resztę z dzielenia
	xor	rbx,	rbx
	xor	rdx,	rdx

	; najmniejszą liczbą całkowitą jest
	mov	r8,	1	; jedności

.loop:
	; pobierz cyfrę w postaci kodu ASCII
	movzx	rax,	byte [rdi]
	; usuń kod ASCII
	sub	rax,	VARIABLE_ASCII_CODE_NUMBER
	; przelicz wartość/wagę cyfry z danej pozycji
	mul	r8

	; brak obsługi liczb o rozmiarze powyżej 64 bitów
	cmp	rdx,	VARIABLE_EMPTY
	jne	.error

	; dodaj do wyniku
	add	rbx,	rax

	; oblicz wartość/wagę nastepnej pozycji cyfry
	mov	rax,	r8
	mul	r9

	; brak obsługi systemu liczbowego o rozmiarze powyżej 64 bitów
	cmp	rdx,	VARIABLE_EMPTY
	jne	.error

	; ustaw nową wartość/wagę cyfry
	mov	r8,	rax
	; przesuń wskaźnik na następną pozycję
	dec	rdi
	; kontynuj z pozostałymi cyframi
	loop	.loop

	; zwróć wynik w rejestrze RAX
	mov	qword [rsp + VARIABLE_QWORD_SIZE * 0x06],	rbx

	; wyliczenia gotowe
	clc

.end:
	; przywróć oryginalne rejestry
	pop	r9
	pop	r8
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

.error:
	; brak wyniku
	stc

	; koniec
	jmp	.end
