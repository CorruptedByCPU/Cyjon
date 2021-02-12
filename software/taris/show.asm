;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	bx - struktura bloku
;	r8 - wskaźnik do struktury elementu draw
taris_show_block:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rbx

	; struktura figury do wyświetlania
	mov	rsi,	taris_rgl_square

	; ustaw kolor figury
	mov	dword [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.color],	r11d

.loop:
	; wyczyść akumulator
	xor	eax,	eax

	; 4 bity na wiersz
	mov	cx,	TARIS_BRICK_STRUCTURE_width

	; wyczyść starszą część
	xor	edx,	edx

	; pobierz pozycję bitu od najmłodszego
	bsf	ax,	bx
	jz	.end	; wyświetlono cały blok

	; wyłącz
	btr	bx,	ax

	; wylicz numer wiersza
	div	cx

	; zachowaj względną pozycję na osi X
	push	rdx

	; wylicz bezwzględną pozycję na osi Y
	add	rax,	r10
	mov	ecx,	TARIS_BRICK_HEIGHT_pixel + TARIS_BRICK_PADDING_pixel
	mul	rcx

	; uzupełnij strukturę figury
	mov	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.y],	ax

	; przywróć względną pozycję na osi Y
	pop	rax

	; wylicz bezwzględną pozycję na osi X
	add	rax,	r9
	mov	ecx,	TARIS_BRICK_WIDTH_pixel + TARIS_BRICK_PADDING_pixel
	mul	rcx

	; uzupełnij strukturę figury
	mov	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.x],	ax

	; wyświetl pierwszy fragment bloku
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_square

	; następna figura bloku
	jmp	.loop

.end:
	; przywróć oryginalne rejestry
	pop	rbx
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
