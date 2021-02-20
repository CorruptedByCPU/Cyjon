;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
 taris_interface:
 	; aktualizuj etykietę "punkty"
	call	taris_interface_points

 	; aktualizuj etykietę "poziom"
	call	taris_interface_level

 	; aktualizuj etykietę "linie"
	call	taris_interface_lines

	; powrót z procedury
	ret

;===============================================================================
; wyjście:
;	Flaga CF - jeśli rozmiar punktów przekracza 7 cyfr
taris_interface_points:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; załaduj do etykiety aktualną ilość punków
	mov	eax,	dword [taris_points_total]
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx
	mov	rdi,	taris_window.element_label_points_value_string
	macro_library	LIBRARY_STRUCTURE_ENTRY.integer_to_string

	; aktualizuj ilość cyfr w etykiecie
	mov	byte [taris_window.element_label_points_value_length],	cl

	; przeładuj etykietę
	mov	rsi,	taris_window.element_label_points_value
	mov	rdi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_element_label

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
taris_interface_level:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; załaduj do etykiety aktualną numer poziomu
	mov	eax,	dword [taris_level_current]
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx
	mov	rdi,	taris_window.element_label_level_value_string
	macro_library	LIBRARY_STRUCTURE_ENTRY.integer_to_string

	; aktualizuj ilość cyfr w etykiecie
	mov	byte [taris_window.element_label_level_value_length],	cl

	; przeładuj etykietę
	mov	rsi,	taris_window.element_label_level_value
	mov	rdi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_element_label

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
taris_interface_lines:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; załaduj do etykiety aktualną ilość linii
	mov	eax,	dword [taris_lines]
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx
	mov	rdi,	taris_window.element_label_lines_value_string
	macro_library	LIBRARY_STRUCTURE_ENTRY.integer_to_string

	; aktualizuj ilość cyfr w etykiecie
	mov	byte [taris_window.element_label_lines_value_length],	cl

	; przeładuj etykietę
	mov	rsi,	taris_window.element_label_lines_value
	mov	rdi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_element_label

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
