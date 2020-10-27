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
; wyjście:
;	rax - wartość
;	rbx - typ
;		0 - Bytes
;		1 - KiB
;		2 - MiB
;		3 - GiB
;		4 - TiB
;		5 - PiB
;		6 - EiB
;		7 - ZiB
;		8 - YiB
;	rdx - procent z reszty
library_value_to_size:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rax

	; inicjuj rozmiar
	xor	ebx,	ebx

	; podstawowy przelicznik rozmiaru
	mov	ecx,	1024

	; domyślny procent z reszty
	xor	edx,	edx

	; wartość mniejsza od podstawy?
	cmp	rax,	1024
	jb	.end	; tak, brak przeliczania

.loop:
	; przelicz oryginalną wartość na odpowiedni rozmiar
	mov	rax,	qword [rsp]
	div	rcx

	; następny rozmiar wartości
	shl	rcx,	STATIC_MULTIPLE_BY_1024_shift

	; przeliczono do następnego rozmiaru
	inc	bl

	; wartość wynikowa mniejsza od podstawy?
	cmp	rax,	1024
	jae	.loop	; tak, przelicz na inny rozmiar

	; zachowaj wynik całkowity
	mov	qword [rsp],	rax

	; resztę przelicz na %
	mov	rax,	rdx
	mov	edx,	100
	shr	rcx,	STATIC_MULTIPLE_BY_1024_shift	; koryguj podstawę wyniku
	mul	rdx
	div	rcx

	; zwróć procent
	mov	rdx,	rax

.end:
	; przywróć oryginalne rejestry
	pop	rax
	pop	rcx

	; powrót z procedury
	ret
