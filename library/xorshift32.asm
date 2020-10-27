;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - ziarno
; wyjście:
;	rax - wartość "losowa"
library_xorshift32:
	; zachowaj oryginalne rejestry
	push	rdx

	mov	edx,	eax
	shl	eax,	13
	xor	eax,	edx
	mov	edx,	eax
	shr	eax,	17
	xor	eax,	edx
	mov	edx,	eax
	shl	eax,	5
	xor	eax,	edx

	; przywróć oryginalne rejestry
	pop	rdx

	; powrót z procedury
	ret
