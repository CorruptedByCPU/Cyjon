;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
taris_show_empty:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; wyczyść przestrzeń gry
	mov	ax,	TARIS_PLAYGROUND_EMPTY_bits
	mov	ecx,	TARIS_PLAYGROUND_HEIGHT_brick
	mov	rdi,	taris_brick_platform
	rep	stosw

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
taris_show_playground:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r12
	push	r13

	; struktura figury do wyświetlania
	mov	rsi,	taris_rgl_square

	; wskaźnik do tablicy kolorów
	mov	r13,	qword [taris_playground_colors_table]

	; ustaw pozycję na osi Y pierwszego bloku przestrzeni gry
	mov	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.y],	STATIC_EMPTY

	; ustaw kolor przestrzeni gry
	mov	dword [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.color],	0x00AAAAAA

	; struktura przestrzeni gry
	mov	rdi,	taris_brick_platform

	; wysokość przestrzeni do przetworzenia
	mov	r12,	TARIS_PLAYGROUND_HEIGHT_brick

.next:
	; pobierz pierwszą linię przestrzeni gry
	movzx	ebx,	word [rdi]

	; ukryj pierwsze dwie kolumny
	shr	bx,	STATIC_DIVIDE_BY_4_shift

.loop:
	; pobierz pozycję bitu od najmłodszego
	bsf	eax,	ebx
	jz	.end	; wyświetlono cały blok

	; nie bierz pod uwagę prawej krawędzi
	cmp	ax,	TARIS_PLAYGROUND_WIDTH_brick
	jae	.end	; prawa krawędź

	; wyłącz
	btr	bx,	ax

	; zachowaj oryginalny numer bitu
	push	rax

	; przesuń numer bitu na pozycję
	mov	cx,	TARIS_BRICK_WIDTH_pixel + TARIS_BRICK_PADDING_pixel
	mul	cx

	; uzupełnij strukturę figury
	mov	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.x],	ax

	; przywróć oryginalny numer bitu
	pop	rax
	add	rax,	STATIC_MULTIPLE_BY_4_shift	; weź pod uwagę pierwsze dwie kolumny

	; pobierz kolor figury
	mov	eax,	dword [r13 + rax * STATIC_DWORD_SIZE_byte]

	; uzupełnij kolor
	mov	dword [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.color],	eax

	; wyświetl pierwszy fragment bloku
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_square

	; następna figura bloku
	jmp	.loop

.end:
	; przesuń wskaźnik na następną linię przestrzeni gry
	add	rdi,	STATIC_WORD_SIZE_byte

	; następne bloki rysuj od nastepnej linii
	add	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.y],	TARIS_BRICK_WIDTH_pixel + TARIS_BRICK_PADDING_pixel

	; koryguj wskaźnik o następny wiersz
	add	r13,	STATIC_DWORD_SIZE_byte << STATIC_MULTIPLE_BY_16_shift

	; przetworzono całą przestrzeń gry?
	dec	r12
	jnz	.next	; nie

	; przywróć oryginalne rejestry
	pop	r13
	pop	r12
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	bx - struktura bloku
;	r8 - wskaźnik do struktury elementu draw
taris_show_block:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r9

	; pierwsze dwie kolumny są niewidoczne
	sub	r9,	STATIC_WORD_SIZE_byte

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
	pop	r9
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
