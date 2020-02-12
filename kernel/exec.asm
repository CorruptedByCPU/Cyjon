;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; wejście:
;	rcx - ilość znaków reprezentujących nazwę uruchamianego programu
;	rsi - wskaźnik do nazwy programu
;	rdi - wskaźnik do supła pliku
; wyjście:
;	Flaga CF - wystąpił błąd
;	rax - kod błędu, jeśli Flaga CF podniesiona
;	rcx - pid nowego procesu
kernel_exec:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdx
	push	rsi
	push	rbp
	push	r8
	push	r11
	push	rax
	push	rcx
	push	rdi

	; oblicz ilość stron niezbędnych do załadowania pliku do pamięci
	mov	rcx,	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.size]
	call	library_page_from_size

	; zarezerwuj ilość stron, niezbędną do inicjalizacji procesu
	add	rcx,	14
	call	kernel_page_secure
	jc	.error	; brak wystarczającej ilości pamięci

	; poinformuj wszystkie procedury zależne by korzystały z zarezerwowanych stron
	mov	rbp,	rcx

	; utwórz tablicę PML4 procesu
	call	kernel_memory_alloc_page
	call	kernel_page_drain

	; wykorzystano stronę do stronicowania
	inc	qword [kernel_page_paged_count]

	; zachowaj adres
	mov	r11,	rdi

	; przygotuj miejsce pod przestrzeń kodu procesu
	mov	rax,	KERNEL_MEMORY_HIGH_VIRTUAL_address
	mov	ebx,	KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user
	call	kernel_page_map_logical
	jc	.error

	; przygotuj miejsce pod stos procesu
	mov	rax,	(KERNEL_MEMORY_HIGH_VIRTUAL_address << STATIC_MULTIPLE_BY_2_shift) - KERNEL_PAGE_SIZE_byte
	mov	rcx,	KERNEL_PAGE_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	call	kernel_page_map_logical
	jc	.error

	; przygotuj miejsce pod stos kontekstu (należy do jądra systemu)
	mov	rax,	KERNEL_STACK_address
	mov	rbx,	KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
	mov	rcx,	KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	call	kernel_page_map_logical
	jc	.error

	; mapuj przestrzeń jądra systemu
	mov	rsi,	qword [kernel_page_pml4_address]
	mov	rdi,	r11
	call	kernel_page_merge

	; odstaw na początek stosu kontekstu zadania, spreparowane dane powrotu z przerwania sprzętowego "kernel_task"
	mov	rdi,	qword [r8]
	and	di,	KERNEL_PAGE_mask	; usuń flagi rekordu tablicy PML1
	add	rdi,	KERNEL_PAGE_SIZE_byte - ( STATIC_QWORD_SIZE_byte * 0x05 )	; odłóż 5 rejestrów

	; RIP
	mov	rax,	KERNEL_MEMORY_HIGH_REAL_address
	stosq

	; CS
	mov	rax,	KERNEL_STRUCTURE_GDT.cs_ring3 | 0x03
	stosq	; zapisz

	; EFLAGS
	mov	rax,	KERNEL_TASK_EFLAGS_default
	stosq	; zapisz

	; RSP
	mov	rax,	STATIC_EMPTY
	stosq	; zapisz

	; DS
	mov	rax,	KERNEL_STRUCTURE_GDT.ds_ring3 | 0x03
	stosq	; zapisz

	; przywróć wskaźnik do supła pliku
	mov	rsi,	qword [rsp]

	;-----------------------------------------------------------------------
	; przełącz przestrzeń pamięci na proces
	mov	rax,	cr3
	mov	cr3,	r11

	; załaduj kod programu do przestrzeni pamięci procesu
	mov	rdi,	SOFTWARE_base_address
	call	kernel_vfs_file_read

	; przywróć przestrze pamięci na rodzica
	mov	cr3,	rax
	;-----------------------------------------------------------------------

	; wstaw proces do kolejki zadań
	mov	ebx,	KERNEL_TASK_FLAG_active
	movzx	ecx,	byte [rsi + KERNEL_VFS_STRUCTURE_KNOT.length]
	add	rsi,	KERNEL_VFS_STRUCTURE_KNOT.name
	call	kernel_task_add
	jc	.error

	; zwolnij niewykrzystane, zarezerwowane strony
	add	qword [kernel_page_free_count],	rbp
	sub	qword [kernel_page_reserved_count],	rbp

	; zwróć numer PID utworzonego zadania
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rcx

	; koniec obsługi procedury
	jmp	.end

.error:
	; zwróć kod błędu
	mov	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02],	rax

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax
	pop	r11
	pop	r8
	pop	rbp
	pop	rsi
	pop	rdx
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"kernel_exec"
