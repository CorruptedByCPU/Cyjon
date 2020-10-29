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

	; pobierz wysokość przestrzeni znakowej
	movzx	r8,	word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.height]
	sub	r8,	TM_TABLE_FIRST_ROW_y + 0x01	; koryguj o pozycję pierwszego wiersza tablicy (ostatni zawsze pusty)

	; ustaw kursor na pierwszy wiersz tablicy
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_first_row_position_end - tm_string_first_row_position
	mov	rsi,	tm_string_first_row_position
	int	KERNEL_SERVICE

	; pobierz informacje o uruchomionych procesach
	mov	ax,	KERNEL_SERVICE_PROCESS_list
	int	KERNEL_SERVICE

	; zachowaj adres i rozmiar tablicy
	push	rcx
	push	rsi

	; rcx - rozmiar tablicy
	; rsi - wskaźnik do tablicy

.loop:
	; zachowaj właściwości tablicy procesów
	push	rcx
	push	rsi

	; proces jest aktywny?
	test	qword [rsi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active
	jz	.next	; nie, zignoruj

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

	; przywróć wskaźnik do wpisu
	mov	rsi,	qword [rsp]

	; ilość dostępnych znaków dla nazwy procesu
	movzx	ecx,	word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.width]
	sub	ecx,	TM_TABLE_CELL_process_x + 0x01	; pozycja kolumny "Process" na osi X (nie wyświetlaj ostatniego znaku w kolumnie)

	; nazwa procesu większa?
	movzx	eax,	byte [rsi + KERNEL_TASK_STRUCTURE.length]
	cmp	eax,	ecx
	ja	.yes	; tak, wyświetl maksymalną możliwą

	; nie, wyświetl tyle ile jest
	mov	ecx,	eax

.yes:
	; wyświetl nazwę procesu
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	add	rsi,	KERNEL_TASK_STRUCTURE.name
	int	KERNEL_SERVICE

	; wykorzystano wiersz tablicy
	dec	r8
	jz	.next	; brak wolnych wierszy w tablicy

	; przesuń kursor na kolejny wiersz tablicy
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_table_row_next_end - tm_string_table_row_next
	mov	rsi,	tm_string_table_row_next
	int	KERNEL_SERVICE

.next:
	; przywróć właściwości listy procesów
	pop	rsi
	pop	rcx

	; koniec przestrzeni tablicy?
	test	r8,	r8
	jz	.end	; tak, wyczyść pozostałe

	; przesuń wskaźnik do następnego wpisu
	add	rsi,	KERNEL_TASK_STRUCTURE.SIZE

	; koniec wpisów?
	sub	rcx,	KERNEL_TASK_STRUCTURE.SIZE
	jnz	.loop	; nie

.clear:
	; przesuń kursor na kolejny wiersz tablicy
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_table_row_next_end - tm_string_table_row_next
	mov	rsi,	tm_string_table_row_next
	int	KERNEL_SERVICE

	; wyczyścić pozostałe wiersze?
	dec	r8
	jnz	.clear	; tak

.end:
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
