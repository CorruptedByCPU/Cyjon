;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

struc	KERNEL_STRUCTURE_IDT_HEADER
	.limit				resb	2
	.address			resb	8
endstruc

kernel_init_idt:
	; zarezerwuj przestrzeń na Tablicę Deskryptorów Przerwań
	call	kernel_memory_alloc_page
	jc	kernel_init_panic_low_memory

	; wyczyść tablicę IDT i zachowaj jej adres
	call	kernel_page_drain
	mov	qword [kernel_idt_header + KERNEL_STRUCTURE_IDT_HEADER.address],	rdi

	;-----------------------------------------------------------------------
	; domyślna obsługa wyjątków procesora
	mov	rax,	kernel_idt_exception_default
	mov	bx,	KERNEL_IDT_TYPE_exception
	mov	ecx,	32	; wszystkie wyjątki procesora
	call	kernel_idt_update

	;-----------------------------------------------------------------------
	; podłącz procedurę obsługi "spurious interrupt"
	mov	rax,	255
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	rdi,	kernel_idt_spurious_interrupt
	call	kernel_idt_mount

	;-----------------------------------------------------------------------
	; załaduj Tablicę Deskryptorów Przerwań
	lidt	[kernel_idt_header]

	;-----------------------------------------------------------------------
	; włącz wyjątki, przerwania (sprzętowe i programowe)
	sti
