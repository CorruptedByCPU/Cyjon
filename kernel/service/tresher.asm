;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
service_tresher:
	; szukaj zakończonego procesu
	call	service_tresher_search

	; zapamiętaj adres tablicy PML4 procesu
	mov	r11,	qword [rsi + KERNEL_TASK_STRUCTURE.cr3]

	; ustaw wskaźnik na podstawę przestrzeni stosu kontekstu
	mov	rax,	KERNEL_MEMORY_HIGH_VIRTUAL_address

	; pobierz rozmiar stosu wątku
	movzx	ecx,	word [rsi + KERNEL_TASK_STRUCTURE.stack]

	; koryguj pozycję wskaźnika
	shl	rcx,	STATIC_PAGE_SIZE_shift
	sub	rax,	rcx

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
	jmp	service_tresher

	macro_debug	"service_tresher"

;===============================================================================
; wyjście:
;	rsi - wskaźnik do znalezionego rekordu
service_tresher_search:
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

	macro_debug	"service_tresher_search"
