;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rbx - ilość znaków w ciągu
;	rsi - wskaźnik do ciągu
; wyjście:
;	rax - wartość
library_string_to_integer:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r8
	push	rax

	; podstawa cyfry
	mov	ecx,	1

	; wynik cząstkowy
	xor	r8,	r8

.loop:
	; pobierz ostatnią cyfrę z ciągu
	movzx	eax,	byte [rsi + rbx - 0x01]
	sub	al,	STATIC_ASCII_DIGIT_0	; przekształć kod ASCII cyfry na wartość
	mul	rcx	; zamień na wartość z danej podstawy dla cyfry

	; dodaj do wyniku cząstkowego
	add	r8,	rax

	; zamień podstawę na dziesiątki, setki, tysiące... itd.
	mov	eax,	10
	mul	rcx
	mov	rcx,	rax

	; koniec ciągu?
	dec	rbx
	jnz	.loop	; nie, przetwarzaj dalej

	; zwróć wynik
	mov	qword [rsp],	r8

	; przywróć oryginalne rejestry
	pop	rax
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"library_string_to_integer"
