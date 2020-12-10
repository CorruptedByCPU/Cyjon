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

	macro_debug	"software: tm_ram"

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

	macro_debug	"software: tm_ram.show"
