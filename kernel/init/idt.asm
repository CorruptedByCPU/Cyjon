;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_idt:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; prepare area for Interrupt Descriptor Table
	mov	ecx,	TRUE
	call	kernel_memory_alloc
	mov	qword [r8 + KERNEL.idt_header + KERNEL_STRUCTURE_IDT_HEADER.base_address],	rdi

	;-----------------------------------------------------------------------
	; attach processor exception handlers
	mov	rax,	kernel_idt_exception_divide_by_zero
	mov	bx,	KERNEL_IDT_TYPE_gate_interrupt
	mov	ecx,	0
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_debug
	mov	ecx,	1
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_breakpoint
	mov	ecx,	3
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_overflow
	mov	ecx,	4
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_boud_range_exceeded
	mov	ecx,	5
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_invalid_opcode
	mov	ecx,	6
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_device_not_available
	mov	ecx,	7
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_double_fault
	mov	ecx,	8
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_coprocessor_segment_overrun
	mov	ecx,	9
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_invalid_tss
	mov	ecx,	10
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_segment_not_present
	mov	ecx,	11
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_stack_segment_fault
	mov	ecx,	12
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_general_protection_fault
	mov	ecx,	13
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_page_fault
	mov	ecx,	14
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_x87_floating_point
	mov	ecx,	16
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_alignment_check
	mov	ecx,	17
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_machine_check
	mov	ecx,	18
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_simd_floating_point
	mov	ecx,	19
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_virtualization
	mov	ecx,	20
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_control_protection
	mov	ecx,	21
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_hypervisor_injection
	mov	ecx,	28
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_vmm_communication
	mov	ecx,	29
	call	kernel_idt_mount
	mov	rax,	kernel_idt_exception_security
	mov	ecx,	30
	call	kernel_idt_mount
	;-----------------------------------------------------------------------

	; attach software interrupt handler
	mov	rax,	kernel_irq
	mov	bx,	KERNEL_IDT_TYPE_isr
	mov	ecx,	64
	call	kernel_idt_mount

	; attach interrupt handler for "spurious interrupt"
	mov	rax,	kernel_idt_interrupt_spurious
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	ecx,	255
	call	kernel_idt_mount

	; configure header of Interrupt Descriptor Table
	mov	word [r8 + KERNEL.idt_header + KERNEL_STRUCTURE_IDT_HEADER.limit],	STD_PAGE_byte

	; reload Interrupt Descriptor Table
	lidt	[r8 + KERNEL.idt_header]

	; restore original registers
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret