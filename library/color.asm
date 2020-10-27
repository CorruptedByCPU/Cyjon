;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;=======================================================================
; wejście:
;	rsi - kolor ważony
;	rdi - kolor podstawowy
; wyjście:
;	eax - kolor połączony z uwzględnieniem kanału alfa
library_color_alpha:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx

	; zmienna lokalna
	push	STATIC_EMPTY

	; waga (kanał alfa)
	movzx	rbx,	byte [rsi + 0x03]

	; odwróć kanał alfa, używam odwrotnej notacji 0..widoczny, 255..niewidoczny
	not	bl
	inc	bl

	; czerwony -------------------------------------------------------------
	movzx	rax,	byte [rsi + 0x02]

	; ważenie
	mul	bl
	mov	cl,	STATIC_BYTE_mask
	xor	dl,	dl
	div	cl

	; wynik cząstkowy
	mov	byte [rsp + 0x02],	al

	; zielony --------------------------------------------------------------
	mov	al,	byte [rsi + 0x01]

	; ważenie
	mul	bl
	xor	dl,	dl
	div	cl

	; wynik cząstkowy
	mov	byte [rsp + 0x01],	al

	; niebieski ------------------------------------------------------------
	mov	al,	byte [rsi]

	; ważenie
	mul	bl
	xor	dl,	dl
	div	cl

	; wynik cząstkowy
	mov	byte [rsp],	al

	; odwróć kanał alfa
	sub	bl,	STATIC_BYTE_mask
	not	bl
	inc	bl

	; czerwony podstawowy --------------------------------------------------
	mov	al,	byte [rdi + 0x02]

	; ważenie
	mul	bl
	xor	dl,	dl
	div	cl

	; wynik cząstkowy
	add	byte [rsp + 0x02],	al

	; zielony podstawowy ---------------------------------------------------
	mov	al,	byte [rdi + 0x01]

	; ważenie
	mul	bl
	xor	dl,	dl
	div	cl

	; wynik cząstkowy
	add	byte [rsp + 0x01],	al

	; niebieski podstawowy -------------------------------------------------
	mov	al,	byte [rdi]

	; ważenie
	mul	bl
	xor	dl,	dl
	div	cl

	; wynik cząstkowy
	add	byte [rsp],	al

	; zwróć wynik
	pop	rax

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"library_color_alpha"

;===============================================================================
; wejście:
;	rcx - ilość danych obrazu w Bajtach
;	rsi - wskaźnik do danych obrazu
library_color_alpha_invert:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; zamień rozmiar na ilość pikseli
	shr	rcx,	KERNEL_VIDEO_DEPTH_shift

.loop:
	; pobierz wartość kanału alfa
	mov	al,	byte [rsi + 0x03]

	; wartość całkowicie niewidoczna?
	test	al,	al
	jz	.invisible	; tak

	; koryguj wartość
	dec	al

.invisible:
	; odwróć wartość
	not	al

	; odłóż na miejsce
	mov	byte [rsi + 0x03],	al

	; przesuń wskaźnik na następną wartość kanału alfa
	add	rsi,	KERNEL_VIDEO_DEPTH_byte

	; przetworzyć kolejne piksele?
	dec	rcx
	jnz	.loop	; tak

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"library_color_alpha_invert"
