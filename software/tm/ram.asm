;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
tm_ram:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10

	; pobierz informacje o przestrzeni pamięci RAM
	mov	ax,	KERNEL_SERVICE_SYSTEM_memory
	int	KERNEL_SERVICE

	; ustaw kursor na pozycję "total"
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_memory_total_position_and_color_end - tm_string_memory_total_position_and_color
	mov	rsi,	tm_string_memory_total_position_and_color
	int	KERNEL_SERVICE

	; wyświetl wartość w KiB
	mov	rax,	r8
	call	.show

	; ustaw kursor na pozycję "free"
	mov	ecx,	tm_string_memory_total_end - tm_string_memory_total
	mov	rsi,	tm_string_memory_total
	int	KERNEL_SERVICE

	; wyświetl wartość w KiB
	mov	rax,	r9
	call	.show

	; ustaw kursor na pozycję "used"
	mov	ecx,	tm_string_memory_free_end - tm_string_memory_free
	mov	rsi,	tm_string_memory_free
	int	KERNEL_SERVICE

	; wyświetl wartość w KiB
	mov	rax,	r8
	sub	rax,	r9
	call	.show

	; zakończ
	mov	ecx,	tm_string_memory_used_end - tm_string_memory_used
	mov	rsi,	tm_string_memory_used
	int	KERNEL_SERVICE

	; przyróć oryginalne rejestry
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; wejście:
;	rax - wartość do wyświetlenia w KiB
.show:
	; zamień rozmiar całkowity przestrzeni na KiB
	shl	rax,	STATIC_MULTIPLE_BY_PAGE_shift	; zamień strony na Bajty
	mov	ecx,	1024
	xor	edx,	edx
	div	rcx	; zamień KiB

	; przekształć wartość na ciąg
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx	; bez prefiksu
	mov	rdi,	tm_string_value_format
	call	library_integer_to_string

	; wyświetl wartość
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; powrót z podprocedury
	ret

; ;===============================================================================
; tm_ram:
; 	; zachowaj oryginalne rejestry
; 	push	rax
; 	push	rbx
; 	push	rcx
; 	push	rdx
; 	push	rsi
; 	push	rdi
;
; 	; przelicz ilość wolnej przestrzeni na odpowiedni typ oraz resztę w procentach
; 	mov	rax,	r9
; 	shl	rax,	STATIC_MULTIPLE_BY_PAGE_shift	; zamień strony na Bajty
; 	call	library_value_to_size
;
; 	; formatuj ciąg wyjściowy rozmiaru
; 	mov	rdi,	tm_string_ram_value
; 	call	tm_ram_format
;
; 	; pobierz typ wartości
; 	mov	rsi,	tm_string_size_values
; 	mov	bl,	byte [rsi + rbx]
;
; 	; dołącz do ciągu
; 	mov	byte [rdi + TR_STRING_RAM_length - 0x01],	bl
;
; 	; wyświetl całkowitą część wartości
; 	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
; 	mov	ecx,	tm_string_ram_part_one_end - tm_string_ram_part_one
; 	mov	rsi,	tm_string_ram_part_one
; 	int	KERNEL_SERVICE
; 	mov	ecx,	0x04
; 	mov	rsi,	tm_string_ram_value
; 	int	KERNEL_SERVICE
;
; 	; wyświetl procent reszty wartości
; 	mov	ecx,	tm_string_ram_part_two_end - tm_string_ram_part_two
; 	mov	rsi,	tm_string_ram_part_two
; 	int	KERNEL_SERVICE
; 	mov	ecx,	0x02
; 	mov	rsi,	tm_string_ram_value + 0x04
; 	int	KERNEL_SERVICE
;
; 	; wyświetl oznaczenie wartości
; 	mov	ecx,	tm_string_ram_part_tree_end - tm_string_ram_part_tree
; 	mov	rsi,	tm_string_ram_part_tree
; 	int	KERNEL_SERVICE
; 	mov	ecx,	0x01
; 	mov	rsi,	tm_string_ram_value + 0x06
; 	int	KERNEL_SERVICE
;
; 	; przywróć oryginalne rejestry
; 	pop	rdi
; 	pop	rsi
; 	pop	rdx
; 	pop	rcx
; 	pop	rbx
; 	pop	rax
;
; 	; powrót z procedury
; 	ret
; ;===============================================================================
; ; wejście:
; ;	rax - wartość całkowita
; ;	rdx - procent z reszty
; ;	rdi - wskaźnik docelowy konstruowanego ciągu
; tm_ram_format:
; 	; zachowaj oryginalne rejestry
; 	push	rax
; 	push	rbx
; 	push	rcx
; 	push	rdi
; 	push	rdx
;
; 	; zamień wartość całkowitą na ciąg
; 	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
; 	mov	ecx,	0x04	; maksymalny rozmiar prefiksu
; 	mov	dl,	STATIC_ASCII_SPACE	; prefiks
; 	call	library_integer_to_string
;
; 	; zamień procent reszty na ciąg
; 	mov	rax,	qword [rsp]	; pobierz procent reszty
; 	add	rdi,	rcx	; przesuń wskaźnik za wartość całkowitą
; 	mov	ecx,	2	; maksymalny rozmiar prefiksu
; 	mov	dl,	STATIC_ASCII_DIGIT_0	; prefiks
; 	call	library_integer_to_string
;
; 	; przywróć oryginalne rejestry
; 	pop	rdx
; 	pop	rdi
; 	pop	rcx
; 	pop	rbx
; 	pop	rax
;
; 	; powrót z procedury
; 	ret
