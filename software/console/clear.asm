;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
console_clear:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rdi

	; ustaw wskaźnik na przestrzeń danych okna
	mov	rdi,	qword [console_window + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; przesuń wskaźnik na przestrzeń danych elementu "draw_0"
	mov	rax,	qword [console_window.element_draw_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_DRAW.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	mul	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline]
	add	rdi,	rax

	; rozmiar przestrzeni elementu "draw_0"
	mov	rax,	qword [console_window + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline]
	mul	qword [console_window.element_draw_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	shr	rax,	KERNEL_VIDEO_DEPTH_shift

	; wyczyść
	mov	rcx,	rax
	mov	eax,	CONSOLE_WINDOW_BACKGROUND_color
	rep	stosd

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
