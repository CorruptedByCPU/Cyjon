;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
soler_show:
	; domyślnie wyświetl pierwszą wartość
	mov	rax,	r10

	; wyświetlić pierwszą czy drugą wartość?
	test	r12b,	r12b
	jz	.first	; pierwsza

	; wyświetl drugą wartość
	mov	rax,	r11

.first:
	; zamień wartość na ciąg
	mov	bl,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx	; brak prefiksu
	mov	rdi,	soler_window.element_label_string
	call	library_integer_to_string

	; ciąg zmieści się w etykiecie?
	cmp	rcx,	SOLER_INPUT_SIZE_overflow
	jb	.end	; tak

	; wyświetl komunikat błędu
	mov	cl,	STATIC_QWORD_SIZE_byte	; rozmiar komunikatu błędu
	mov	qword [soler_window.element_label_string],	" ERR"

.end:
	; ustaw rozmiar ciągu w etykiecie
	mov	byte [soler_window.element_label_length],	cl

	; powrót z peocedury
	ret
