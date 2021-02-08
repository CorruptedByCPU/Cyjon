;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rsi - wskaźnik do właściwości kwadratu
;	r8 - wskaźnik do właściwości RGL
library_rgl_square:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rdi
	push	r9
	push	r10

	; scanline kwadratu
	movzx	r9,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.width]
	shl	r9,	KERNEL_VIDEO_DEPTH_shift

	; wylicz pozycję bezwzględną elementu w przestrzeni danych okna
	movzx	eax,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.y]
	mul	r9	; scanline
	movzx	edi,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.x]
	shl	rdi,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax
	add	rdi,	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.address]

	; pobierz kolor kwadratu
	mov	eax,	dword [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.color]

	; wysokość kwadratu
	movzx	r10,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.height]

.loop:
	; zmień kolor pikseli na całej szerokości przestrzeni kwadratu
	movzx	rcx,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.width]
	rep	stosd

	; przesuń wskaźnik na następną linię pikseli w przestrzeni kwadratu
	sub	rdi,	r9	; scanline kwadratu
	add	rdi,	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.scanline]	; scanline kwadratu

	; koniec przestrzeni kwadratu?
	dec	r10
	jnz	.loop	; nie, kontynuuj

	; przywróć oryginalne rejestry
	pop	r10
	pop	r9
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"library_rgl"
