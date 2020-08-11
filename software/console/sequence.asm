;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
; wejście:
;	rcx - ilość znaków ciągu
;	rsi - wskaźnik do ciągu
;	r8 - wskaźnik do właściwości terminala
console_sequence:
	; w ciągu pozostało wystarczająco znaków dla sekwencji?
	cmp	rcx,	STATIC_ASCII_SEQUENCE_length
	jb	.end	; nie

	; zachowaj licznik i wskaźnik
	push	rdi
	push	rcx

	; rozmiar sekwencji w znakach
	mov	rcx,	STATIC_ASCII_SEQUENCE_length

	;-----------------------------------------------------------------------
	; czarny?
	mov	rdi,	console_string_sequence_color_black
	call	library_string_compare
	jc	.no_black	; nie

	; kolor czarny
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_black
	jmp	.found	; kontynuuj

.no_black:
	;-----------------------------------------------------------------------
	; niebieski?
	mov	rdi,	console_string_sequence_color_blue
	call	library_string_compare
	jc	.no_blue	; nie

	; kolor niebieski
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_blue
	jmp	.found	; kontynuuj

.no_blue:
	;-----------------------------------------------------------------------
	; zielony?
	mov	rdi,	console_string_sequence_color_green
	call	library_string_compare
	jc	.no_green	; nie

	; kolor zielony
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_green
	jmp	.found	; kontynuuj

.no_green:
	;-----------------------------------------------------------------------
	; cyjan?
	mov	rdi,	console_string_sequence_color_cyan
	call	library_string_compare
	jc	.no_cyan	; nie

	; kolor cyjan
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_cyan
	jmp	.found	; kontynuuj

.no_cyan:
	;-----------------------------------------------------------------------
	; czerwony?
	mov	rdi,	console_string_sequence_color_red
	call	library_string_compare
	jc	.no_red	; nie

	; kolor czerwony
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_red
	jmp	.found	; kontynuuj

.no_red:
	;-----------------------------------------------------------------------
	; magenta?
	mov	rdi,	console_string_sequence_color_magenta
	call	library_string_compare
	jc	.no_magenta	; nie

	; kolor magenta
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_magenta
	jmp	.found	; kontynuuj

.no_magenta:
	;-----------------------------------------------------------------------
	; brązowy?
	mov	rdi,	console_string_sequence_color_brown
	call	library_string_compare
	jc	.no_brown	; nie

	; kolor brązowy
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_brown
	jmp	.found	; kontynuuj

.no_brown:
	;-----------------------------------------------------------------------
	; jasno-szary?
	mov	rdi,	console_string_sequence_color_gray_light
	call	library_string_compare
	jc	.no_gray_light	; nie

	; kolor jasno-szary
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_gray_light
	jmp	.found	; kontynuuj

.no_gray_light:
	;-----------------------------------------------------------------------
	; szary?
	mov	rdi,	console_string_sequence_color_gray
	call	library_string_compare
	jc	.no_gray	; nie

	; kolor szary
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_gray
	jmp	.found	; kontynuuj

.no_gray:
	;-----------------------------------------------------------------------
	; jasno-niebieski?
	mov	rdi,	console_string_sequence_color_blue_light
	call	library_string_compare
	jc	.no_blue_light	; nie

	; kolor jasno-niebieski
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_blue_light
	jmp	.found	; kontynuuj

.no_blue_light:
	;-----------------------------------------------------------------------
	; jasno-zielony?
	mov	rdi,	console_string_sequence_color_green_light
	call	library_string_compare
	jc	.no_green_light	; nie

	; kolor jasno-zielony
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_green_light
	jmp	.found	; kontynuuj

.no_green_light:
	;-----------------------------------------------------------------------
	; jasny cyjan?
	mov	rdi,	console_string_sequence_color_cyan_light
	call	library_string_compare
	jc	.no_cyan_light	; nie

	; kolor jasny cyjan
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_cyan_light
	jmp	.found	; kontynuuj

.no_cyan_light:
	;-----------------------------------------------------------------------
	; jasno-czerwony?
	mov	rdi,	console_string_sequence_color_red_light
	call	library_string_compare
	jc	.no_red_light	; nie

	; kolor jasno-czerwony
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_red_light
	jmp	.found	; kontynuuj

.no_red_light:
	;-----------------------------------------------------------------------
	; jasna magenta?
	mov	rdi,	console_string_sequence_color_magenta_light
	call	library_string_compare
	jc	.no_magenta_light	; nie

	; kolor jasna magenta
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_magenta_light
	jmp	.found	; kontynuuj

.no_magenta_light:
	;-----------------------------------------------------------------------
	; żółty?
	mov	rdi,	console_string_sequence_color_yellow
	call	library_string_compare
	jc	.no_yellow	; nie

	; kolor żółty
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_yellow
	jmp	.found	; kontynuuj

.no_yellow:
	;-----------------------------------------------------------------------
	; biały?
	mov	rdi,	console_string_sequence_color_white
	call	library_string_compare
	jc	.no_white	; nie

	; kolor biały
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	STATIC_COLOR_white
	jmp	.found	; kontynuuj

.no_white:
	;-----------------------------------------------------------------------
	; odwrócić kolory?
	mov	rdi,	console_string_sequence_color_invert
	call	library_string_compare
	jc	.error	; nie

	; odwróć kolory
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color]
	xchg	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.background_color]
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	eax

.found:
	; przesuń wskaźnik poza sekwencje
	add	rsi,	rcx

	; zmniejsz rozmiar ciągu o przetworzoną sekwencje
	sub	qword [rsp],	STATIC_ASCII_SEQUENCE_length

	; flaga, sukces
	clc

	; koniec
	jmp	.return

.error:
	; flaga, błąd
	stc

.return:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rdi

.end:
	; powrót z procedury
	ret
