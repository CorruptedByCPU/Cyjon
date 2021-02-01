;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	bx - model bloku
taris_collision:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	r9

	; zamienna lokalna
	push	TARIS_BRICK_STRUCTURE_height

.loop:
	; pobierz pierwszą linię struktury bloku
	mov	al,	bl
	and	al,	STATIC_BYTE_LOW_mask

	; przesuń linię struktury bloku na miejsce
	mov	cl,	r8b
	shl	ax,	cl

	; pobierz linię przestrzeni planszy odpowiadającej pozycji linii struktury bloku
	mov	rdx,	taris_brick_platform
	mov	dx,	word [rdx + r9 * STATIC_WORD_SIZE_byte]

	; wystąpiła kolizja?
	test	ax,	dx
	jz	.no_collision	; nie

	; cdn.
	nop

.no_collision:
	; następna linia struktury modelu bloku
	shr	bx,	STATIC_MOVE_AL_HALF_TO_LOW_shift

	; następna linia przestrzeni planszy
	inc	r9

	; przetworzono cały model bloku?
	dec	qword [rsp]
	jnz	.loop	; nie

.end:
	; zwolnij zmienną lokalną
	pop	rax

	; przywróć oryginalne rejestry
	pop	r9
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
