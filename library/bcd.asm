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

library_bcd_to_binary:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	mov	al,	bl
	; usuń starszą cyfrę
	and	al,	00001111b
	; zapamiętaj młodszą cyfrę
	push	rax

	mov	al,	bl
	; przesuń starszą cyfrę w miejsce młodszej
	shr	al,	4
	; zamień na system dziesiętny
	mov	cl,	10
	; wykonaj
	mul	cl
	; przywróć młodszą cyfrę
	pop	rcx
	; dodaj do starszej
	add	al,	cl
	; zapamiętaj format Binarny
	mov	bl,	al

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

	;powrót z procedury
	ret
