;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
taris_inject:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	r10

	; zamienna lokalna
	push	TARIS_BRICK_STRUCTURE_height

	; wskaźnik do przestrzeni platformy
	mov	rdi,	taris_brick_platform

.loop:
	; pobierz pierwszą linię struktury bloku
	movzx	ax,	bl
	and	al,	STATIC_BYTE_LOW_mask

	; przesuń linię struktury bloku na miejsce
	mov	cl,	r9b
	shl	ax,	cl

	; połącz linię bloku z przestrzenią gry
	or	word [rdi + r10 * STATIC_WORD_SIZE_byte],	ax

	; następna linia struktury modelu bloku
	shr	bx,	STATIC_MOVE_AL_HALF_TO_LOW_shift

	; następna linia przestrzeni planszy
	inc	r10

	; przetworzono cały model bloku?
	dec	qword [rsp]
	jnz	.loop	; nie

.end:
	; zwolnij zmienną lokalną
	pop	rax

	; przywróć oryginalne rejestry
	pop	r10
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
