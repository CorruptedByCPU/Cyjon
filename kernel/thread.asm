;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rsi - wskaźnik do danych dla wątku
;	rdi - wskaźnik początku kodu wątku
kernel_thread:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi
	push	r8
	push	r11

	; przygotuj miejsce na nową tablicę stronicowania dla wątku
	call	kernel_memory_alloc_page
	jc	.end	; brak miejsca

	; wyczyść tablicę PML4
	call	kernel_page_drain

	; utwórz nowy stos kontekstu dla wątku
	mov	rax,	KERNEL_STACK_address
	mov	ebx,	KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
	mov	ecx,	KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	mov	r11,	rdi
	call	kernel_page_map_logical

	; odstaw na początek stosu kontekstu zadania, spreparowane dane powrotu z przerwania sprzętowego "kernel_task"
	mov	rdi,	qword [r8]
	and	di,	STATIC_PAGE_mask	; usuń flagi rekordu tablicy PML1
	add	rdi,	STATIC_PAGE_SIZE_byte - ( STATIC_QWORD_SIZE_byte * 0x05 )	; odłóż 5 rejestrów

	; RIP
	mov	rax,	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02]
	stosq

	; CS
	mov	rax,	KERNEL_STRUCTURE_GDT.cs_ring0
	stosq	; zapisz

	; EFLAGS
	mov	rax,	KERNEL_TASK_EFLAGS_default
	stosq	; zapisz

	; RSP
	mov	rax,	KERNEL_STACK_pointer
	stosq	; zapisz

	; DS
	mov	rax,	KERNEL_STRUCTURE_GDT.ds_ring0
	stosq	; zapisz

	; ostaw wskaźnik do danych dla wątku
	mov	qword [rdi - STATIC_QWORD_SIZE_byte * 0x0B],	rsi

	; mapuj przestrzeń procesu rodzica
	mov	rsi,	cr3
	mov	rdi,	r11
	call	kernel_page_merge

	; wstaw zadanie jako wstrzymane do kolejki procesora logicznego, który jest najmniej obciążony
	mov	bx,	KERNEL_TASK_FLAG_active | KERNEL_TASK_FLAG_thread | KERNEL_TASK_FLAG_secured
	call	kernel_task_add

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	r8
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_thread"
