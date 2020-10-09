;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
; wejście:
;	rax - rozmiar w Bajtach
tm_ram:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; przelicz ilość wolnej przestrzeni na odpowiedni typ oraz resztę w procentach
	mov	rax,	r9
	shl	rax,	STATIC_MULTIPLE_BY_PAGE_shift	; zamień strony na Bajty
	call	library_value_to_size

	; formatuj ciąg wyjściowy rozmiaru
	mov	rdi,	tm_string_ram_value
	call	tm_ram_format

	; pobierz typ wartości
	mov	rsi,	tm_string_size_values
	mov	bl,	byte [rsi + rbx]

	; dołącz do ciągu
	mov	byte [rdi + TR_STRING_RAM_length - 0x01],	bl

	; wyświetl całkowitą część wartości
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_ram_part_one_end - tm_string_ram_part_one
	mov	rsi,	tm_string_ram_part_one
	int	KERNEL_SERVICE
	mov	ecx,	0x04
	mov	rsi,	tm_string_ram_value
	int	KERNEL_SERVICE

	; wyświetl procent reszty wartości
	mov	ecx,	tm_string_ram_part_two_end - tm_string_ram_part_two
	mov	rsi,	tm_string_ram_part_two
	int	KERNEL_SERVICE
	mov	ecx,	0x02
	mov	rsi,	tm_string_ram_value + 0x04
	int	KERNEL_SERVICE

	; wyświetl oznaczenie wartości
	mov	ecx,	tm_string_ram_part_tree_end - tm_string_ram_part_tree
	mov	rsi,	tm_string_ram_part_tree
	int	KERNEL_SERVICE
	mov	ecx,	0x01
	mov	rsi,	tm_string_ram_value + 0x06
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rax - wartość całkowita
;	rdx - procent z reszty
;	rdi - wskaźnik docelowy konstruowanego ciągu
tm_ram_format:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	rdx

	; zamień wartość całkowitą na ciąg
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	mov	ecx,	0x04	; maksymalny rozmiar prefiksu
	mov	dl,	STATIC_ASCII_SPACE	; prefiks
	call	library_integer_to_string

	; zamień procent reszty na ciąg
	mov	rax,	qword [rsp]	; pobierz procent reszty
	add	rdi,	rcx	; przesuń wskaźnik za wartość całkowitą
	mov	ecx,	2	; maksymalny rozmiar prefiksu
	mov	dl,	STATIC_ASCII_DIGIT_0	; prefiks
	call	library_integer_to_string

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
