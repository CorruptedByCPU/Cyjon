;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_idt:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; assign space for IDT and store it
	mov	ecx,	STATIC_PAGE_SIZE_page
	call	kernel_memory_alloc
	mov	qword [kernel_idt_header + KERNEL_IDT_STRUCTURE_HEADER.address],	rdi

	;-----------------------------------------------------------------------
	; attach processor exception handlers
	mov	rax,	kernel_idt_exception_divide_by_zero
	mov	bx,	KERNEL_IDT_TYPE_exception
	mov	ecx,	0
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_debug
	mov	ecx,	1
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_breakpoint
	mov	ecx,	3
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_overflow
	mov	ecx,	4
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_boud_range_exceeded
	mov	ecx,	5
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_invalid_opcode
	mov	ecx,	6
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_device_not_available
	mov	ecx,	7
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_double_fault
	mov	ecx,	8
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_coprocessor_segment_overrun
	mov	ecx,	9
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_invalid_tss
	mov	ecx,	10
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_segment_not_present
	mov	ecx,	11
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_stack_segment_fault
	mov	ecx,	12
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_general_protection_fault
	mov	ecx,	13
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_page_fault
	mov	ecx,	14
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_x87_floating_point
	mov	ecx,	16
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_alignment_check
	mov	ecx,	17
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_machine_check
	mov	ecx,	18
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_simd_floating_point
	mov	ecx,	19
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_virtualization
	mov	ecx,	20
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_control_protection
	mov	ecx,	21
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_hypervisor_injection
	mov	ecx,	28
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_vmm_communication
	mov	ecx,	29
	call	kernel_idt_update
	mov	rax,	kernel_idt_exception_security
	mov	ecx,	30
	call	kernel_idt_update
	;-----------------------------------------------------------------------

	; attach software interrupt handler
	mov	rax,	kernel_irq
	mov	bx,	KERNEL_IDT_TYPE_isr
	mov	ecx,	64
	call	kernel_idt_update

	; attach interrupt handler for "spurious interrupt"
	mov	rax,	kernel_idt_spurious_interrupt
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	ecx,	255
	call	kernel_idt_update

	; reload Global Descriptor Table
	lidt	[kernel_idt_header]

	; restore original registers
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rax - pointer to interrupt handler
;	bx - interrupt type
;	rcx - entry number
kernel_idt_update:
	; preserve original registers
	push	rax
	push	rcx
	push	rdi

	; retirve pointer to IDT structure
	mov	rdi,	qword [kernel_idt_header + KERNEL_IDT_STRUCTURE_HEADER.address]

	; move pointer to entry
	shl	cx,	STATIC_MULTIPLE_BY_16_shift
	or	di,	cx

	; low bits of address (15...0)
	mov	word [rdi + KERNEL_IDT_STRUCTURE_ENTRY.address_low],	ax

	; middle bits of address (31...16)
	shr	rax,	STATIC_MOVE_HIGH_TO_AX_shift
	mov	word [rdi + KERNEL_IDT_STRUCTURE_ENTRY.address_middle],	ax

	; high bits of address (63...32)
	shr	rax,	STATIC_MOVE_HIGH_TO_AX_shift
	mov	dword [rdi + KERNEL_IDT_STRUCTURE_ENTRY.address_high],	eax

	; code descriptor of kernel environment
	mov	word [rdi + KERNEL_IDT_STRUCTURE_ENTRY.cs],	KERNEL_GDT_STRUCTURE.cs_ring0

	; type of interrupt
	mov	word [rdi + KERNEL_IDT_STRUCTURE_ENTRY.type],	bx

	; restore original registers
	pop	rdi
	pop	rcx
	pop	rax

	; return from routine
	ret