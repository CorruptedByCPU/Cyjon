;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
service_gc:
	; szukaj zakończonego procesu
	call	service_gc_search

	; zamknij wszystkie okna utworzone przez proces
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.pid]
	call	kernel_wm_object_drain

	; pobierz identyfikator strumienia wejścia procesu
	mov	rdi,	qword [rsi + KERNEL_TASK_STRUCTURE.in]

	; strumień wejścia jest własnością procesu?
	test	qword [rsi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_stream_in
	jnz	.stream_not_unique	; nie

	; zwolnij strumień
	call	kernel_stream_release

.stream_not_unique:
	; pobierz identyfikator strumienia wyjścia procesu
	mov	rdi,	qword [rsi + KERNEL_TASK_STRUCTURE.out]

	; strumień wyjścia jest własnością procesu?
	test	qword [rsi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_stream_out
	jnz	.stream_out_unique	; nie

	; zwolnij strumień
	call	kernel_stream_release

.stream_out_unique:
	; zapamiętaj adres tablicy PML4 procesu
	mov	r11,	qword [rsi + KERNEL_TASK_STRUCTURE.cr3]

	; ustaw wskaźnik na podstawę przestrzeni stosu kontekstu
	mov	rax,	KERNEL_MEMORY_HIGH_VIRTUAL_address
	movzx	ecx,	word [rsi + KERNEL_TASK_STRUCTURE.stack]	; rozmiar stosu kontekstu wątku
	shl	rcx,	STATIC_PAGE_SIZE_shift	; zamień na Bajty
	sub	rax,	rcx	; koryguj pozycję wskaźnika

	; zwolnij przestrzeń stosu kontekstu wątku
	shr	rcx,	STATIC_PAGE_SIZE_shift
	call	kernel_memory_release_foreign

	; proces był wątkiem?
	test	word [rsi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_thread
	jnz	.pml4	; tak, brak przestrzeni kodu/danych

	; zwolnij przestrzeń kodu/danych procesu
	mov	rax,	KERNEL_MEMORY_HIGH_VIRTUAL_address
	mov	rcx,	STATIC_MAX_unsigned	; do końca przestrzeni pamięci logicznej
	call	kernel_memory_release_foreign

.pml4:
	; zwolnij przestrzeń tablicy PML4 wątku
	mov	rdi,	r11
	call	kernel_memory_release_page	; zwolnij przestrzeń tablicy PML4

	; strona odzyskana z tablic stronicowania
	dec	qword [kernel_page_paged_count]

	; zwolnij wpis w kolejce zadań
	mov	word [rsi + KERNEL_TASK_STRUCTURE.flags],	STATIC_EMPTY

	; ilość zadań w kolejce
	dec	qword [kernel_task_count]

	; ilość dostępnych rekordów w kolejce zadań
	inc	qword [kernel_task_free]

	; szukaj nowego procesu do zwolnienia
	jmp	service_gc

	macro_debug	"service_gc"

;===============================================================================
; wyjście:
;	rsi - wskaźnik do znalezionego rekordu
service_gc_search:
	; zachowaj oryginalne rejestry
	push	rcx

	; przeszukaj od początku kolejkę za zamkniętym wpisem
	mov	rsi,	qword [kernel_task_address]

.restart:
	; ilość wpisów na blok danych kolejki zadań
	mov	rcx,	STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

.next:
	; sprawdź flagę zamkniętego procesu
	test	word [rsi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_closed
	jnz	.found

	; przesuń wskaźnik na następny rekord
	add	rsi,	KERNEL_TASK_STRUCTURE.SIZE

	; szukaj dalej?
	dec	rcx
	jnz	.next	; tak

	; pobierz adres następnego bloku kolejki zadań
	and	si,	STATIC_PAGE_mask
	mov	rsi,	qword [rsi + STATIC_STRUCTURE_BLOCK.link]
	jmp	.restart

.found:
	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"service_gc_search"
