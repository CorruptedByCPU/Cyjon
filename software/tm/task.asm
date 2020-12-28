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
	push	rcx
	push	rsi
	push	rdi

	; ustaw kursor na pierwszy wiersz listy procesów
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_first_row_position_end - tm_string_first_row_position
	mov	rsi,	tm_string_first_row_position
	int	KERNEL_SERVICE

	; pobierz informacje o uruchomionych procesach
	mov	ax,	KERNEL_SERVICE_PROCESS_list
	int	KERNEL_SERVICE

	; wyświetl uruchomione procesy
	call	tm_task_show

	; zwolnij przestrzeń uruchomionych procesów
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_release
	mov	rdi,	rsi
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"software: tm_task"

;===============================================================================
; wejście:
;	rbx-  rozmiar całkowity elementów na liście w Bajtach
;	rcx - rozmiar przestrzeni listy w Bajtach
;	rsi - wskaźnik do początku przestrzeni listy
tm_task_show:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9

	; wylicz ilość wolnych wierszy
	movzx	r8,	word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.height]
	sub	r8w,	word [tm_string_first_row_position.y]
	dec	r8w	; liczymy od zera

	; ilość procesów
	xor	r9,	r9

	; posortuj listę elementów względem kolumny %CPU od najmniejszej wartości
	call	tm_task_sort

	; rbx - ilość procesów na liście
	; rsi - wskaźnik do listy

	; zachowaj ilość procesów na liście
	push	rbx

.loop:
	; zachowaj wslaźnik początku listy
	push	rsi

	; proces typu "usługa systemu"?
	test	word [rsi + KERNEL_TASK_STRUCTURE_ENTRY.flags],	KERNEL_TASK_FLAG_service
	jnz	.next	; tak, pomiń

	; pobierz PID pierwszego procesu z listy
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE_ENTRY.pid]

	; przekształć wartość na ciąg
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	mov	ecx,	5	; uzupełnij wartośc o prefix do piętego miejsca
	mov	dl,	STATIC_SCANCODE_SPACE	; prefix
	mov	rdi,	tm_string_value_format
	call	library_integer_to_string

	; wyświetl wartość
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	;-----------------------------------------------------------------------

	; pobierz wartość APIC pierwszego procesu z listy
	mov	rsi,	qword [rsp]
	mov	eax,	dword [rsi + KERNEL_TASK_STRUCTURE_ENTRY.apic]

	; przekształć wartość na procent bez reszty
	call	tm_percent

	; zamień wartość na ciąg
	call	library_integer_to_string

	; wyświetl wartość
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	;-----------------------------------------------------------------------

	; pobierz wartość Memory pierwszego procesu z listy
	mov	rsi,	qword [rsp]
	mov	eax,	dword [rsi + KERNEL_TASK_STRUCTURE_ENTRY.memory]

	; przekształć wartość na procent bez reszty
	call	tm_percent

	; zamień wartość na ciąg
	call	library_integer_to_string

	; wyświetl wartość
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	;-----------------------------------------------------------------------

	; pobierz aktualne zegary systemu
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; pobierz wartość Time pierwszego procesu z listy
	mov	rsi,	qword [rsp]
	sub	rax,	qword [rsi + KERNEL_TASK_STRUCTURE_ENTRY.time]

	; wyświetl wartość
	call	tm_uptime

	;-----------------------------------------------------------------------

	; przesuń kursor na kolumnę "Process"
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x1
	int	KERNEL_SERVICE

	; przywróć wskaźnik do wpisu
	mov	rsi,	qword [rsp]

	; ilość dostępnych znaków dla nazwy procesu
	movzx	ecx,	word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.width]
	sub	ecx,	TM_TABLE_CELL_process_x + 0x01	; pozycja kolumny "Process" na osi X (nie wyświetlaj ostatniego znaku w kolumnie)

	; nazwa procesu większa?
	movzx	eax,	byte [rsi + KERNEL_TASK_STRUCTURE_ENTRY.length]
	cmp	eax,	ecx
	ja	.yes	; tak, wyświetl maksymalną możliwą

	; nie, wyświetl tyle ile jest
	mov	ecx,	eax

.yes:
	; wyświetl nazwę procesu
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	add	rsi,	KERNEL_TASK_STRUCTURE_ENTRY.name
	int	KERNEL_SERVICE

	; wykorzystano wiersz listy
	dec	r8
	jz	.end	; brak wolnych wierszy w listy

	; przesuń kursor na kolejny wiersz listy
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_table_row_next_end - tm_string_table_row_next
	mov	rsi,	tm_string_table_row_next
	int	KERNEL_SERVICE

.next:

	; przesuń wskaźnik do następnego wpisu
	movzx	eax,	byte [rsi + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add	eax,	KERNEL_TASK_STRUCTURE_ENTRY.SIZE
	add	rsi,	rax

	; koniec elementów na liście?
	sub	rbx,	rax
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
	; przywróć ilość procesów na liście
	pop	rbx

	; wyświetl ilość uruchomionych procesów

	; ustaw kursor na pozycję
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_tasks_position_and_color_end - tm_string_tasks_position_and_color
	mov	rsi,	tm_string_tasks_position_and_color
	int	KERNEL_SERVICE

	; przekształć wartość na ciąg
	mov	rax,	rbx
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx	; bez prefiksu
	mov	rdi,	tm_string_value_format
	call	library_integer_to_string

	; wyświetl
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; ustaw kursor na pozycję "wątki"
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_tasks_total_end - tm_string_tasks_total
	mov	rsi,	tm_string_tasks_total
	int	KERNEL_SERVICE

	; przekształć wartość na ciąg
	mov	eax,	r9d
	shr	eax,	STATIC_MOVE_HIGH_TO_AX_shift
	xor	ecx,	ecx	; bez prefiksu
	call	library_integer_to_string

	; wyświetl
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; wyświetl typ
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_tasks_threads_end - tm_string_tasks_threads
	mov	rsi,	tm_string_tasks_threads
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
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

	macro_debug	"software: tm_task_show"

;===============================================================================
; wejście:
;	rbx - rozmiar wszystkich elmentów na liście w Bajtach
;	rsi - wskaźnik do listy
tm_task_sort:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

.next:
	; zachowaj ilość wpisów na liście oraz zmienną lokalną
	push	rbx
	push	STATIC_TRUE	; lista nie była modyfikowana

	; pozycja względna elementu aktualnego
	xor	ecx,	ecx

.loop:
	; koniec listy elementów?
	dec	rbx
	jz	.terminated	; nie

	; pozycja względna elementu następnego
	movzx	edx,	byte [rsi + rcx + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add	rdx,	rcx
	add	rdx,	KERNEL_TASK_STRUCTURE_ENTRY.name

	; wartość elementu[rcx] większa od elementu[rdx]?
	mov	rax,	qword [rsi + rcx + KERNEL_TASK_STRUCTURE_ENTRY.pid]
	cmp	rax,	qword [rsi + rdx + KERNEL_TASK_STRUCTURE_ENTRY.pid]
	jbe	.no	; nie

	; zamień elementy miejscami
	call	tm_task_replace

	; zmodyfikowano listę
	mov	byte [rsp],	STATIC_FALSE

.no:
	; następny element z listy
	xchg	rcx,	rdx

	; kontynuuj sortowanie
	jmp	.loop

.terminated:
	; przywróć zmienną lokalną i ilość wpisów na liście
	pop	rax
	pop	rbx

	; lista posortowana?
	test	al,	al
	jnz	.next	; tak

.end:
	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"software: tm_task_sort"

;===============================================================================
; wejście:
;	rcx - indeks pierwszego elementu
;	rdx - indeks drugiego elementu
;	rsi - wskaźnik początku przestrzeni danych
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

	macro_debug	"software: tm_task_replace"
