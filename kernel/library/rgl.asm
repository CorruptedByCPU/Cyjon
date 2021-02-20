;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	r8 - wskaźnik do właściwości RGL
library_rgl:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; przygotuj przestrzeń roboczą
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_alloc
	mov	rcx,	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.size]
	int	KERNEL_SERVICE

	; zachowaj wskaźnik do przestrzeni roboczej
	mov	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.workspace_address],	rdi

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"library_rgl"

;===============================================================================
; wejście:
;	r8 - wskaźnik do właściwości RGL
library_rgl_flush:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r9

	; scanline przestrzeni okna
	mov	rax,	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.scanline]

	; szerokość przestrzeni roboczej w pikselach
	movzx	ebx,	word [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.width]

	; wysokość przestrzeni roboczej w pikselach
	movzx	edx,	word [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.height]

	; przestrzeń robocza i okna
	mov	rsi,	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.workspace_address]
	mov	rdi,	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.address]

	; scanline przestrzeni roboczej
	mov	r9,	rbx
	shl	r9,	KERNEL_VIDEO_DEPTH_shift

.loop:
	; pierwsza linia pikseli
	mov	rcx,	rbx
	rep	movsd	; synchronizuj

	; przesuń wskaźnik docelowy na następną linię pikseli
	add	rdi,	rax	; scanline przestrzeni okna
	sub	rdi,	r9	; scanline przestrzeni roboczej

	; koniec przestrzeni roboczej?
	dec	rdx
	jnz	.loop	; nie

	; przywróć oryginalne rejestry
	pop	r9
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"library_rgl_flush"

;===============================================================================
; wejście:
;	r8 - wskaźnik do właściwości RGL
library_rgl_clear:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; pobierz kolor tła
	mov	eax,	dword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.background_color]

	; rozmiar przestrzeni w Bajtach
	mov	rcx,	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.size]
	shr	rcx,	KERNEL_VIDEO_DEPTH_shift	; zamień na piksele

	; wyczyść
	mov	rdi,	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.workspace_address]
	rep	stosd

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"library_rgl_clear"

;===============================================================================
; wejście:
;	rsi - wskaźnik do właściwości kwadratu
;	r8 - wskaźnik do właściwości RGL
library_rgl_square:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13

	; zmienne lokalne
	sub	rsp,	STATIC_QWORD_SIZE_byte

	; scanline przestrzeni roboczej
	movzx	r10,	word [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.width]
	shl	r10,	KERNEL_VIDEO_DEPTH_shift

	; szerokość i wysokość figury
	movzx	r11,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.width]
	movzx	r12,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.height]

	; pozycja figury na osi X,Y
	movzx	r13,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.x]
	movzx	r14,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.y]

	; figura w przestrzeni roboczej?

	; na osi X z lewej?
	mov	rax,	r13
	add	rax,	r11
	cmp	rax,	STATIC_EMPTY
	jl	.end	; nie

	; na osi X z prawej?
	cmp	r13w,	word [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.width]
	jge	.end	; nie

	; na osi Y od góry?
	mov	rax,	r14
	add	rax,	r12
	cmp	rax,	STATIC_EMPTY
	jl	.end	; nie

	; na osi Y od dołu?
	cmp	r14w,	word [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.height]
	jge	.end	; nie

	; ogranicz rysowanie niewidocznej części figury

	; figura poza przestrzenią roboczą na osi X z lewej strony?
	bt	r13w,	STATIC_WORD_BIT_sign
	jnc	.x_on_right	; nie

	; koryguj pozycję na osi X
	mov	rax,	r13
	not	ax
	sub	r11w,	ax
	jz	.end	; figura niewidoczna
	js	.end	; figura niewidoczna

	; nowa pozycja figury na osi X
	xor	r13,	r13

.x_on_right:
	; figura poza przestrzenią roboczą na osi Y od góry?
	bt	r14w,	STATIC_WORD_BIT_sign
	jnc	.y_on_bottom	; nie

	; koryguj pozycję na osi Y
	mov	rax,	r14
	not	ax
	sub	r12w,	ax
	jz	.end	; figura niewidoczna
	js	.end	; figura niewidoczna

	; nowa pozycja figury na osi Y
	xor	r14,	r14

.y_on_bottom:
	;-----------------------------------------------------------------------
	; pozycja na osi X
	mov	rax,	r13
	add	rax,	r11
	movzx	ebx,	word [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.width]
	sub	rax,	rbx
	js	.x_visible	; cała widoczna

	; koryguj szerokość
	sub	r11,	rax

.x_visible:
	; pozycja na osi Y
	mov	rax,	r14
	add	rax,	r12
	movzx	ebx,	word [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.height]
	sub	rax,	rbx
	js	.y_visible	; cała widoczna

	; koryguj wysokość
	sub	r12,	rax

.y_visible:
 	;-----------------------------------------------------------------------
 	; pozycja na osi Y
	mov	rax,	r14
	mul	r10	; scanline

	; pozycja na osi X
	mov	rdi,	r13
	shl	rdi,	KERNEL_VIDEO_DEPTH_shift

	; adres bezpośredni w przestrzeni roboczej
	add	rdi,	rax
	add	rdi,	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.workspace_address]

	; pobierz kolor figury
	mov	eax,	dword [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.color]

	; scanline figury
	mov	r9,	r11
	shl	r9,	KERNEL_VIDEO_DEPTH_shift

.loop:
	; zmień kolor pikseli na całej szerokości przestrzeni figury
	mov	rcx,	r11
	rep	stosd

	; przesuń wskaźnik na następną linię pikseli w przestrzeni figury
	sub	rdi,	r9	; scanline figury
	add	rdi,	r10	; scanline przestrzeni roboczej

	; koniec przestrzeni figury?
	dec	r12
	jnz	.loop	; nie, kontynuuj

.end:
	; zwolnij zmienne lokalne
	add	rsp,	STATIC_QWORD_SIZE_byte

	; przywróć oryginalne rejestry
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"library_rgl_square"
