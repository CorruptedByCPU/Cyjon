;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; wejście:
;	rcx - ilość znaków w ciągu
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
	mov	ebx,	1

	; wynik cząstkowy
	xor	r8,	r8

.loop:
	; pobierz ostatnią cyfrę z ciągu
	movzx	eax,	byte [rsi + rcx - 0x01]
	sub	al,	STATIC_ASCII_DIGIT_0	; przekształć kod ASCII cyfty na wartość
	mul	rbx	; zamień na wartość z danej podstawy dla cyfry

	; dodaj do wyniku cząstkowego
	add	r8,	rax

	; zamień podstawę na dziesiątki, setki, tysiące... itd.
	mov	eax,	10
	mul	rbx
	mov	rbx,	rax

	; koniec ciągu?
	dec	rcx
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

	; macro_debug	"library_string_to_integer"
