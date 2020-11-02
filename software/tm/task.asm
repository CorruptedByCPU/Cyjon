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
	sub	r8,	TM_TABLE_FIRST_ROW_y + 0x01	; koryguj o pozycję pierwszego elementu listy (ostatni zawsze pusty)

	; ustaw kursor na pierwszy element listy
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_first_row_position_end - tm_string_first_row_position
	mov	rsi,	tm_string_first_row_position
	int	KERNEL_SERVICE

	; pobierz informacje o uruchomionych procesach
	mov	ax,	KERNEL_SERVICE_PROCESS_list
	int	KERNEL_SERVICE

	; zachowaj adres i rozmiar listy
	push	rcx
	push	rsi

	; przygotuj listę elementów do posortowania
	shl	rbx,	STATIC_MULTIPLE_BY_8_shift
	sub	rsp,	rbx
	mov	rdi,	rsp
	shr	rbx,	STATIC_DIVIDE_BY_8_shift
	call	tm_task_list

	xchg	bx,bx

	; posortuj listę od najmniejszego elementu
	xor	eax,	eax
	dec	rbx
	call	tm_task_sort_quick

	; rcx - rozmiar listy w Bajtach
	; rsi - wskaźnik do listy

.loop:
	; zachowaj właściwości listy procesów
	push	rbx
	push	rcx
	push	rsi

; 	; pobierz PID pierwszego procesu z listy
; 	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE_ENTRY.pid]
;
; 	; przekształć wartość na ciąg
; 	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
; 	mov	ecx,	5	; uzupełnij wartośc o prefix do piętego miejsca
; 	mov	dl,	STATIC_ASCII_SPACE	; prefix
; 	mov	rdi,	tm_string_value_format
; 	call	library_integer_to_string
;
; 	; wyświetl wartość
; 	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
; 	mov	rsi,	rdi
; 	int	KERNEL_SERVICE
;
; 	;------
; 	; debug
; 	;------
; 	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
; 	mov	ecx,	0x11
; 	mov	dl,	STATIC_ASCII_SPACE
; 	int	KERNEL_SERVICE
; 	;------
;
; 	; przywróć wskaźnik do wpisu
; 	mov	rsi,	qword [rsp]
;
; 	; ilość dostępnych znaków dla nazwy procesu
; 	movzx	ecx,	word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.width]
; 	sub	ecx,	TM_TABLE_CELL_process_x + 0x01	; pozycja kolumny "Process" na osi X (nie wyświetlaj ostatniego znaku w kolumnie)
;
; 	; nazwa procesu większa?
; 	movzx	eax,	byte [rsi + KERNEL_TASK_STRUCTURE_ENTRY.length]
; 	cmp	eax,	ecx
; 	ja	.yes	; tak, wyświetl maksymalną możliwą
;
; 	; nie, wyświetl tyle ile jest
; 	mov	ecx,	eax
;
; .yes:
; 	; wyświetl nazwę procesu
; 	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
; 	add	rsi,	KERNEL_TASK_STRUCTURE_ENTRY.name
; 	int	KERNEL_SERVICE
;
; 	; wykorzystano wiersz listy
; 	dec	r8
; 	jz	.next	; brak wolnych wierszy w listy

	; przesuń kursor na kolejny wiersz listy
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_table_row_next_end - tm_string_table_row_next
	mov	rsi,	tm_string_table_row_next
	int	KERNEL_SERVICE

.next:
	; przywróć właściwości listy procesów
	pop	rsi
	pop	rcx
	pop	rbx

	; przesuń wskaźnik do następnego wpisu
	add	rsi,	KERNEL_TASK_STRUCTURE_ENTRY.SIZE

	; koniec elementów na liście?
	dec	rbx
	jnz	.loop	; nie

.clear:
	; przesuń kursor na kolejny wiersz listy
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

;===============================================================================
; wejście:
;	rbx - ilość elementów na liście
;	rsi - wskaźnik do listy elementów
;	rdi - wskaźnik do listy docelowej
tm_task_list:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rsi
	push	rdi

.loop:
	; odłóż do listy docelowej wartość APIC elementu
	mov	eax,	dword [rsi + KERNEL_TASK_STRUCTURE_ENTRY.apic]
	stosq

	; przesuń wskaźnik listy źródłowej na następny element
	movzx	eax,	byte [rsi + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add	eax,	KERNEL_TASK_STRUCTURE_ENTRY.name
	add	rsi,	rax

	; koniec elementów źródłowych?
	dec	rbx
	jnz	.loop	; nie

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rax - indeks pierwszego elementu
;	rbx - indeks ostatniego elementu
;	rdi - wskaźnik do listy
tm_task_sort_quick:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi

	; fragment większy od jednego elementu?
	cmp	rax,	rbx
	jnb	.end	; nie, koniec sortowania



.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rax - indeks pierwszego elementu
;	rbx - indeks ostatniego elementu
;	rdi - wskaźnik do listy
; wyjście:
;	rcx - indeks elementu rozdzielającego
tm_task_sort_quick_divide:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	; wybierz indeks elementu rozdzielającego
	call	tm_task_sort_quick_select
	push	rcx	; zapamiętaj

	; zapamiętaj wartość podziału
	push	qword [rdi + rcx * STATIC_QWORD_SIZE_byte]

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rax - indeks pierwszego elementu
;	rbx - indeks ostatniego elementu
; wyjście:
;	rcx - indeks elementu rozdzielającego
tm_task_sort_quick_select:
	; zachowaj oryginalne rejestry
	push	rbx

	; koryguj indeks ostatniego elementu listy
	dec	rbx

	; rozmiar listy w elementach
	mov	rcx,	rax
	add	rcx,	rbx
	shr	rcx,	STATIC_DIVIDE_BY_2_shift

	; przywróć oryginalne rejestry
	pop	rbx

	; powróz procedury
	ret

;===============================================================================
; wejście:
;	rbx - indeks ostatniego elementu
;	rcx - indeks elementu rozdzielającego
;	rdi - wskaźnik do listy
tm_task_sort_quick_move:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; wskaźnik do ostatniego elementu
	mov	eax,	KERNEL_TASK_STRUCTURE_ENTRY.SIZE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
