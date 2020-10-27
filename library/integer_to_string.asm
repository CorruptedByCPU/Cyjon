;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - wartość
;	rbx - system liczbowy (podstawa: 2..36)
;	rcx - ilość znaków na prefiks
;	dl - kod ASCII prefiksu
;	rdi - wskaźnik docelowy ciągu
; wyjście:
;	Flaga CF, jeśli niepoprawna podstawa
;	rcx - ilość przetworzonych cyfr
library_integer_to_string:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rdi
	push	rbp
	push	r9
	push	rcx

	; system liczbowy obsługiwany?
	cmp	rbx,	2
	jb	.error	; nie
	cmp	rbx,	36
	ja	.error	; nie

	; zachowaj wartość prefiksa
	mov	r9,	rdx

	; wyczyść starszą część / resztę z dzielenia
	xor	rdx,	rdx

	; utwórz stos zmiennych lokalnych
	mov	rbp,	rsp

.loop:
	; oblicz resztę z dzielenia
	div	rbx

	; zapisz resztę z dzielenia do zmiennych lokalnych
	add	rdx,	STATIC_ASCII_DIGIT_0	; przemianuj cyfrę na kod ASCII
	push	rdx

	; zmniejsz rozmiar prefiksu
	dec	rcx

	; wyczyść resztę z dzielenia
	xor	rdx,	rdx

	; przeliczać dalej?
	test	rax,	rax
	jnz	.loop	; tak

	; uzupełnić prefiks?
	cmp	rcx,	STATIC_EMPTY
	jle	.init	; nie

.prefix:
	; uzupełnij wartość o prefiks
	push	r9

	; uzupełniać dalej?
	dec	rcx
	jnz	.prefix	; tak

.init:
	; ilość przetworzonych cyfr
	xor	ecx,	ecx

.return:
	; pozostały cyfry do wyświetlenia?
	cmp	rsp,	rbp
	je	.end	; nie

	; pobierz cyfrę
	pop	rax

	; sprawdź czy system liczbowy powyżej podstawy 10
	cmp	al,	0x3A
	jb	.no	; jeśli nie, kontynuuj

	; koryguj kod ASCII do odpowiedniej podstawy liczbowej
	add	al,	0x07

.no:
	; zwróć cyfrę
	stosb

	; przetworzona cyfra
	inc	rcx

	; kontynuuj
	jmp	.return

.error:
	; flaga, błąd
	stc

.end:
	; zwróć informacje o ilości przetworzonych cyfr
	mov	qword [rsp],	rcx

	; przywróć oryginalne rejestry
	pop	rcx
	pop	r9
	pop	rbp
	pop	rdi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret
