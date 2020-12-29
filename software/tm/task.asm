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

	; posortuj listę elementów względem kolumny %CPU od najmniejszej wartości
	call	tm_task_sort

	; rbx - ilość procesów na liście
	; rsi - wskaźnik do listy

	; zachowaj ilość procesów na liście
	push	rbx

	; zachowaj wskaźnik aktualnego elementu listy procesów
	mov	rdi,	rsi

	; ilość rozpoznanych wątków
	xor	r9,	r9

.loop:
	; proces typu "wątek"?
	test	word [rdi + KERNEL_TASK_STRUCTURE_ENTRY.flags],	KERNEL_TASK_FLAG_thread
	jz	.no_thread	; nie

	; zlicz wątek
	inc	r9

.no_thread:
	; proces typu "usługa"?
	test	word [rdi + KERNEL_TASK_STRUCTURE_ENTRY.flags],	KERNEL_TASK_FLAG_service
	jnz	.next	; tak, pomiń

	;-----------------------------------------------------------------------

	; wyświetl PID procesu
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	push	qword [rdi + KERNEL_TASK_STRUCTURE_ENTRY.pid]
	pop	qword [tm_string_number.value]	; PID
	mov	byte [tm_string_number.prefix],	TM_TABLE_CELL_pid_width
	mov	ecx,	tm_string_number_end - tm_string_number
	mov	rsi,	tm_string_number
	int	KERNEL_SERVICE

	;-----------------------------------------------------------------------

	; pobierz wartość APIC pierwszego procesu z listy
	mov	eax,	dword [rdi + KERNEL_TASK_STRUCTURE_ENTRY.apic]

	; przekształć wartość na procent bez reszty
	call	tm_percent

	; wyświetl zajętość procesora przez proces
	mov	qword [tm_string_number.value],	rax
	mov	byte [tm_string_number.prefix],	TM_TABLE_CELL_cpu_width
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	int	KERNEL_SERVICE

	;-----------------------------------------------------------------------

	; pobierz wartość APIC pierwszego procesu z listy
	mov	eax,	dword [rdi + KERNEL_TASK_STRUCTURE_ENTRY.memory]

	; przekształć wartość na procent bez reszty
	call	tm_percent

	; wyświetl zajętość procesora przez proces
	mov	qword [tm_string_number.value],	rax
	mov	byte [tm_string_number.prefix],	TM_TABLE_CELL_mem_width
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	int	KERNEL_SERVICE

	;-----------------------------------------------------------------------

	; pobierz aktualne zegary systemu
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; pobierz wartość Time pierwszego procesu z listy
	sub	rax,	qword [rdi + KERNEL_TASK_STRUCTURE_ENTRY.time]

	; wyświetl wartość
	call	tm_uptime

	;-----------------------------------------------------------------------

	; przesuń kursor na kolumnę "Process"
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x1
	int	KERNEL_SERVICE

	; ilość dostępnych znaków dla nazwy procesu
	movzx	ecx,	word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.width]
	sub	ecx,	TM_TABLE_CELL_process_x + 0x01	; pozycja kolumny "Process" na osi X (nie wyświetlaj ostatniego znaku w kolumnie)

	; nazwa procesu większa?
	movzx	eax,	byte [rdi + KERNEL_TASK_STRUCTURE_ENTRY.length]
	cmp	eax,	ecx
	ja	.yes	; tak, wyświetl maksymalną możliwą

	; nie, wyświetl tyle ile jest
	mov	ecx,	eax

.yes:
	; wyświetl nazwę procesu
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	add	rsi,	KERNEL_TASK_STRUCTURE_ENTRY.name
	int	KERNEL_SERVICE

	; pozostały wolne wiersze tablicy?
	dec	r8
	jz	.end	; nie

	; przesuń kursor na kolejny wiersz listy
	mov	ecx,	tm_string_table_row_next_end - tm_string_table_row_next
	mov	rsi,	tm_string_table_row_next
	int	KERNEL_SERVICE

.next:
	; przesuń wskaźnik do następnego wpisu
	movzx	eax,	byte [rdi + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add	rax,	KERNEL_TASK_STRUCTURE_ENTRY.name
	add	rdi,	rax

	; koniec listy procesów?
	dec	rbx
	jnz	.loop	; nie

	; pozostałe wiersze wyczyść
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_table_row_next_end - tm_string_table_row_next
	mov	rsi,	tm_string_table_row_next

.clear:
	; wyczyścić pozostałe wiersze?
	dec	r8
	jz	.end	; nie

	; przesuń kursor na kolejny pusty wiersz tablicy
	int	KERNEL_SERVICE

	; kontynuuj
	jmp	.clear

.end:
	; wyświetl ilość uruchomionych procesów

	; ustaw kursor na pozycję
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_tasks_position_and_color_end - tm_string_tasks_position_and_color
	mov	rsi,	tm_string_tasks_position_and_color
	int	KERNEL_SERVICE

	; wyświetl ilość procesów
	pop	qword [tm_string_number.value]	; PID
	mov	ecx,	tm_string_number_end - tm_string_number
	mov	rsi,	tm_string_number
	mov	byte [tm_string_number.prefix],	STATIC_EMPTY
	int	KERNEL_SERVICE

	; wyświetl ilość wątków

	; ustaw kursor na pozycję
	mov	rsi,	tm_string_tasks_total
	mov	ecx,	tm_string_tasks_total_end - tm_string_tasks_total
	int	KERNEL_SERVICE

	; wyświetl ilość wątków
	mov	qword [tm_string_number.value],	r9
	mov	ecx,	tm_string_number_end - tm_string_number
	mov	rsi,	tm_string_number
	int	KERNEL_SERVICE

	; oznacz jako "wątki"
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

	; koryguj pozycję następnego elementu listy
	movzx	edx,	byte [rsi + rcx + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add	rdx,	rcx
	add	rdx,	KERNEL_TASK_STRUCTURE_ENTRY.name

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

	; zwolnij przestrzeń tymczawą
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
