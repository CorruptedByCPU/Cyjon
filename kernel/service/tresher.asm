;===============================================================================
; Copyright (C) by Andrzej Adamczyk at Blackend.dev
;===============================================================================

;===============================================================================
service_tresher:
	; szukaj zakończonego procesu
	call	service_tresher_search

	; zapamiętaj adres tablicy PML4 procesu
	push	qword [rsi + KERNEL_STRUCTURE_TASK.cr3]

	; zwolnij przestrzeń pamięci przeznaczoną dla procesu
	mov	rbx,	4	; podstawowy poziom tablicy przetwarzanej
	mov	rcx,	1	; ile pozostało rekordów w tablicy PML4 do zwolnienia
	mov	rdi,	qword [rsp]	; adres tablicy PML4 procesu
	add	rdi,	KERNEL_PAGE_SIZE_byte - (257 * STATIC_QWORD_SIZE_byte)	; rozpocznij zwalnianie przestrzeni od przestrzeni stosu kontekstu procesu
	call	kernel_page_release_pml.loop

	; przywróć adres tablicy PML4 procesu
	pop	rdi

	; zwolnij przestrzeń
	call	kernel_memory_release_page

	; strona odzyskana z tablic stronicowania
	dec	qword [kernel_page_paged_count]

	; zwolnij wpis w kolejce zadań
	mov	word [rsi + KERNEL_STRUCTURE_TASK.flags],	STATIC_EMPTY

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
	mov	rcx,	STATIC_STRUCTURE_BLOCK.link / KERNEL_STRUCTURE_TASK.SIZE

.next:
	; sprawdź flagę zamkniętego procesu
	test	word [rsi + KERNEL_STRUCTURE_TASK.flags],	KERNEL_TASK_FLAG_closed
	jnz	.found

	; przesuń wskaźnik na następny rekord
	add	rsi,	KERNEL_STRUCTURE_TASK.SIZE

	; szukaj dalej?
	dec	rcx
	jnz	.next	; tak

	; pobierz adres następnego bloku kolejki zadań
	and	si,	KERNEL_PAGE_mask
	mov	rsi,	qword [rsi + STATIC_STRUCTURE_BLOCK.link]
	jmp	.restart

.found:
	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"service_tresher_search"
