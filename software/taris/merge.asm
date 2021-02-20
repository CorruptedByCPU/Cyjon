;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
taris_merge:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi
	push	r10
	push	rbx

	; zamienna lokalna
	push	TARIS_BRICK_STRUCTURE_height

	; wskaźnik do przestrzeni platformy
	mov	rdi,	taris_brick_platform

.loop:
	; pobierz pierwszą linię struktury bloku
	movzx	eax,	bl
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
	pop	rbx
	pop	r10
	pop	rdi
	pop	rcx
	pop	rax

	; zachowaj kolorystykę figury
	call	taris_merge_colors

	; powrót z procedury
	ret

;===============================================================================
taris_merge_colors:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	r10

	; zamienna lokalna
	push	TARIS_BRICK_STRUCTURE_height

	; wskaźnik do przestrzeni platformy
	mov	rdi,	qword [taris_playground_colors_table]

.line:
	; pobierz pierwszą linię struktury bloku
	movzx	eax,	bl
	and	al,	STATIC_BYTE_LOW_mask

	; przesuń linię struktury bloku na miejsce
	mov	cl,	r9b
	shl	ax,	cl

	; zachowaj wskaźnik początku przestrzeni kolorów i numer wierwsza
	push	rdi
	push	r10

	; koryguj wskaźnik na pozycję względną
	shl	r10,	STATIC_MULTIPLE_BY_64_shift
	add	rdi,	r10

.set:
	; pobierz numer bitu wchodządego w skład bloku
	bsf	rcx,	rax
	jz	.none	; brak bitów

	; wyłącz bit
	btr	rax,	rcx

	; zachowaj kolor bitu
	mov	dword [rdi + rcx * STATIC_DWORD_SIZE_byte],	r11d

	; szukaj następnego
	jmp	.set

.none:
	; przywróć wskaźnik początku przestrzeni kolorów i numer wierwsza
	pop	r10
	pop	rdi

	; następna linia struktury modelu bloku
	shr	bx,	STATIC_MOVE_AL_HALF_TO_LOW_shift

	; następna linia przestrzeni planszy
	inc	r10

	; przetworzono cały model bloku?
	dec	qword [rsp]
	jnz	.line	; nie

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
