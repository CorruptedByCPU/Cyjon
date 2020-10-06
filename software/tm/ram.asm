;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

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
