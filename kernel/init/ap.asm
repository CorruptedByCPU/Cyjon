;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================

	; w tym momencie stos jest niedostępny!

	;-----------------------------------------------------------------------
	; GDT
	;-----------------------------------------------------------------------

	; załaduj Globalną Tablicę Deskryptorów
	lgdt	[kernel_gdt_header]

	;-----------------------------------------------------------------------
	; TSS
	;-----------------------------------------------------------------------

	; pobierz identyfikator procesora logicznego
	mov	rax,	qword [kernel_apic_base_address]
	mov	dword [rax + KERNEL_APIC_TP_register],	STATIC_EMPTY
	mov	eax,	dword [rax + KERNEL_APIC_ID_register]
	shr	eax,	24	; przesuń bity z 24..31 do 0..7

	; załaduj deskryptor Task State Segment dla danego procesora logicznego
	shl	eax,	STATIC_MULTIPLE_BY_16_shift	; oblicz prdesunięcie w tablicy GDT dla selektora TSS
	add	ax,	word [kernel_gdt_tss_bsp_selector]	; koryguj prdesunięcie względem deskryptora procesora BSP
	mov	word [kernel_gdt_tss_cpu_selector],	ax
	ltr	word [kernel_gdt_tss_cpu_selector]

	;-----------------------------------------------------------------------
	; IDT
	;-----------------------------------------------------------------------

	; załaduj Tablicę Deskryptorów Przerwań
	lidt	[kernel_idt_header]

	;=======================================================================
	; TYLKO JEDEN PROCESOR LOGICZNY NA RAZ MOŻE PRZETWARZAĆ PONIŻSZĄ PROCEDURĘ STRONICOWANIA
.wait:	;=======================================================================
	mov	al,	STATIC_TRUE
	lock	xchg	byte [kernel_init_ap_semaphore],	al
	test	al,	al	; sprawdź czy uzyskano dostęp
	jz	.wait	; blokada, spróbuj raz jeszcze
	;=======================================================================

	;-----------------------------------------------------------------------
	; Page
	;-----------------------------------------------------------------------

	; ustaw tymczasowo wskaźnik na tablice stronicowania procesora BSP
	mov	rax,	qword [kernel_page_pml4_address]
	mov	cr3,	rax

	; ustaw tymczasowy wskaźnik szczytu stosu dla procesora logicznego
	mov	rsp,	KERNEL_STACK_TEMPORARY_pointer

	; przygotuj przestrzeń na tablicę PML4 procesora logicznego
	call	kernel_memory_alloc_page
	jc	kernel_panic_memory

	; wyczyść tablicę PML4
	call	kernel_page_drain

	; strona wykorzystana do tablic stronicowania
	inc	qword [kernel_page_paged_count]

	; przygotuj osobny stos/kontekstu dla procesora logicznego
	mov	rax,	KERNEL_STACK_address
	mov	ebx,	KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
	mov	ecx,	KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	mov	r11,	rdi	; dodaj wpis do PML4 procesora logicznego
	xor	ebp,	ebp	; brak stron zarezerwowanych na ten cel
	call	kernel_page_map_logical

	; mapuj pozostałą przestrzeń pamięci na podstawie procesora BSP
	mov	rsi,	qword [kernel_page_pml4_address]
	call	kernel_page_merge

	; przeładuj stronicowanie procesora logicznego
	mov	rax,	rdi
	mov	cr3,	rax

	; ustawiamy wskaźnik szczytu stosu na koniec stosu
	mov	rsp,	KERNEL_STACK_pointer

	; zwolnij dostęp do procedury
	mov	byte [kernel_init_ap_semaphore],	STATIC_FALSE

	;-----------------------------------------------------------------------
	; APIC
	;-----------------------------------------------------------------------
	call	kernel_init_apic

	;-----------------------------------------------------------------------
	; TASK - przydziel pierwszy proces do przetworzenia dla procesora logicznego
	;-----------------------------------------------------------------------

	; wyłącz flagę DF
	cld

	; pobierz identyfikator procesora logicznego
	call	kernel_apic_id_get

	; ustaw wskaźnik na pozycje aktualnego zadania dla procesora logicznego
	mov	rbx,	rax
	shl	rbx,	STATIC_MULTIPLE_BY_8_shift
	mov	rsi,	qword [kernel_task_active_list]

	; ustaw wskaźnik na początek kolejki zadań
	mov	rdi,	qword [kernel_task_address]

	; procesor logiczny zainicjowany
	inc	byte [kernel_init_ap_count]

	; przydziel pierwsze zadanie dla procesora logicznego
	jmp	kernel_task.ap_entry
