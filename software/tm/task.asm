;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
tm_task:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8

	; ustaw kursor na nagłówek listy
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_header_position_end - tm_string_header_position
	mov	rsi,	tm_string_header_position
	int	KERNEL_SERVICE

	; pobierz informacje o uruchomionych procesach
	mov	ax,	KERNEL_SERVICE_PROCESS_list
	int	KERNEL_SERVICE

	; zachowaj adres i rozmiar listy
	push	rcx
	push	rsi

	; rcx - rozmiar listy
	; rsi - wskaźnik do listy

.loop:
	; zachowaj właściwości listy procesów
	push	rcx
	push	rsi

	; proces jest aktywny?
	test	qword [rsi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active
	jz	.next	; nie, zignoruj

	; przesuń kursor na kolejny wiersz listy
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_table_row_next_end - tm_string_table_row_next
	mov	rsi,	tm_string_table_row_next
	int	KERNEL_SERVICE

	; pobierz PID pierwszego procesu z listy
	mov	rax,	qword [rsp]
	mov	rax,	qword [rax + KERNEL_TASK_STRUCTURE.pid]

	; przekształć wartość na ciąg
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	mov	ecx,	5	; uzupełnij wartośc o prefix do piętego miejsca
	mov	dl,	STATIC_ASCII_SPACE	; prefix
	mov	rdi,	tm_string_value_format
	call	library_integer_to_string

	; wyświetl wartość
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	;------
	; debug
	;------
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x11
	mov	dl,	STATIC_ASCII_SPACE
	int	KERNEL_SERVICE
	;------

	; wyświetl nazwę procesu
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	movzx	ecx,	word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.width]
	sub	ecx,	22	; debug
	mov	rsi,	qword [rsp]
	add	rsi,	KERNEL_TASK_STRUCTURE.name
	int	KERNEL_SERVICE

.next:
	; przywróć właściwości listy procesów
	pop	rsi
	pop	rcx

	; przesuń wskaźnik do następnego wpisu
	add	rsi,	KERNEL_TASK_STRUCTURE.SIZE

	; koniec wpisów?
	sub	rcx,	KERNEL_TASK_STRUCTURE.SIZE
	jnz	.loop	; nie

	; przywróć adres i rozmiar listy
	pop	rdi
	pop	rcx

	; zwolnij przestrzeń
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_release
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
