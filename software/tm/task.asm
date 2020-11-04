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

	; posortuj listę elementów względem kolumny %CPU od najmniejszej wartości
	call	tm_task_sort

	; rbx - rozmiar listy w Bajtach
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

	; ; przesuń kursor na kolejny wiersz listy
	; mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	; mov	ecx,	tm_string_table_row_next_end - tm_string_table_row_next
	; mov	rsi,	tm_string_table_row_next
	; int	KERNEL_SERVICE

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
;	rbx - rozmiar wszystkich elmentów na liście w Bajtach
;	rsi - wskaźnik do listy
tm_task_sort:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx

.next:
	; pozycja względna elementu aktualnego
	xor	ecx,	ecx

.loop:
	; pozycja względna elementu następnego
	movzx	edx,	byte [rsi + rcx + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add	rdx,	rcx
	add	rdx,	KERNEL_TASK_STRUCTURE_ENTRY.name

	; koniec elementów na liście?
	cmp	rbx,	rdx
	je	.omit	; koniec pierwszej fazy

	; wartość elementu[rcx] większa od elementu[rcx + 1]?
	mov	eax,	dword [rsi + rcx + KERNEL_TASK_STRUCTURE_ENTRY.apic]
	cmp	eax,	dword [rsi + rdx + KERNEL_TASK_STRUCTURE_ENTRY.apic]
	jbe	.no	; nie

	; zamień elementy miejscami
	call	tm_task_replace

.no:
	; następny element z listy
	xchg	rcx,	rdx

	; kontynuuj
	jmp	.loop

.omit:
	; następna faza
	mov	rbx,	rcx

	; wszystko posortowane?
	test	rbx,	rbx
	jnz	.next	; nie

.end:
	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rcx - indeks pierwszego elementu
;	rdx - indeks drugiego elementu
;	rsi - wskaźnik bezpośredni listy
tm_task_replace:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rbp
	push	r8

	; zapamiętaj indeks pierwszego elementu
	mov	r8,	rcx

	; rozmiar pierwszego elementu
	movzx	ebx,	byte [rsi + r8 + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add	rbx,	KERNEL_TASK_STRUCTURE_ENTRY.SIZE

	; przestrzeń tymczasowa pod element pierwszy
	sub	rsp,	rbx
	mov	rbp,	rsp

.save:
	; odłóż element pierwszy na stos
	mov	al,	byte [rsi + rcx]
	mov	byte [rbp],	al

	; następna wartość elementu
	inc	rcx
	inc	rbp

	; zachowano?
	dec	rbx
	jnz	.save	; nie

	; rozmiar drugiego elementu
	movzx	ebx,	byte [rsi + rdx + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add	rbx,	KERNEL_TASK_STRUCTURE_ENTRY.SIZE

	; prztwróć indeks elementu pierwszego
	mov	rcx,	r8

.element_two:
	; przesuń element drugi w miejsce pierwszego
	mov	al,	byte [rsi + rdx]
	mov	byte [rsi + rcx],	al

	; następna wartość elementu
	inc	rcx
	inc	rdx

	; przeniesiony?
	dec	rbx
	jnz	.element_two

	; początek przestrzeni tymczasowej
	mov	rbp,	rsp

	; rozmiar pierwszego elementu
	movzx	ebx,	byte [rsp + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add	rbx,	KERNEL_TASK_STRUCTURE_ENTRY.SIZE

.restore:
	; przywróć element pierwszy na "pozycję" elementu drugiego
	mov	al,	byte [rbp]
	mov	byte [rsi + rcx],	al

	; następna wartość elementu
	inc	rcx
	inc	rbp

	; przeniesiono?
	dec	rbx
	jnz	.restore	; nie

	; zwolnij przestrzeń tymczasową
	mov	rsp,	rbp

	; przywróć oryginalne rejestry
	pop	r8
	pop	rbp
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
