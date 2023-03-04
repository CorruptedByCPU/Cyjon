;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

; align routine
align	0x08,	db	0x00
kernel_irq:
	; feature available?
	cmp	rax,	(kernel_service_list_end - kernel_service_list) / STATIC_QWORD_SIZE_byte
	jnb	.return	; no

	; preserve original registers
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
	pushf

	; execute kernel function according to parameter in RAX
	call	qword [kernel_service_list + rax * STATIC_QWORD_SIZE_byte]

	; restore original registers
	popf
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

.return:
	; return from interrupt
	iretq

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_divide_by_zero:
	; no Error Code
	push	0
	; exception id
	push	0

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_debug:
	; no Error Code
	push	0
	; exception id
	push	1

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_breakpoint:
	; no Error Code
	push	0
	; exception id
	push	3

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_overflow:
	; no Error Code
	push	0
	; exception id
	push	4

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_boud_range_exceeded:
	; no Error Code
	push	0
	; exception id
	push	5

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_invalid_opcode:
	; no Error Code
	push	0
	; exception id
	push	6

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_device_not_available:
	; no Error Code
	push	0
	; exception id
	push	7

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_double_fault:
	; set exception id
	push	8

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_coprocessor_segment_overrun:
	; no Error Code
	push	0
	; exception id
	push	9

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_invalid_tss:
	; set exception id
	push	10

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_segment_not_present:
	; set exception id
	push	11

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_stack_segment_fault:
	; set exception id
	push	12

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_general_protection_fault:
	; set exception id
	push	13

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_page_fault:
	; set exception id
	push	14

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_x87_floating_point:
	; no Error Code
	push	0
	; exception id
	push	16

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_alignment_check:
	; exception id
	push	17

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_machine_check:
	; no Error Code
	push	0
	; exception id
	push	18

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_simd_floating_point:
	; no Error Code
	push	0
	; exception id
	push	19

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_virtualization:
	; no Error Code
	push	0
	; exception id
	push	20

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_control_protection:
	; exception id
	push	21

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_hypervisor_injection:
	; no Error Code
	push	0
	; exception id
	push	28

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_vmm_communication:
	; exception id
	push	29

	; continue
	jmp	kernel_idt_exception

; align routine
align	0x08,	db	EMPTY
kernel_idt_exception_security:
	; exception id
	push	30

;-------------------------------------------------------------------------------
; void
kernel_idt_exception:
	; keep original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; bochs breakpoint
	xchg	bx,	bx

	; put on the stack value of CR2 register
	mov	rax,	cr2
	push	rax

	; turn off Direction Flag
	cld

	; show on debug console, exception name
	xor	dl,	dl	; string not reversed
	mov	rsi,	qword [rsp + KERNEL_IDT_STRUCTURE_EXCEPTION.id]
	shl	rsi,	STATIC_MULTIPLE_BY_PTR_shift	; offset of entry at exception string table
	add	rsi,	kernel_idt_exception_string	; pointer to exception string table entry
	mov	rsi,	qword [rsi]	; pointer to exception description
	call	lib_string_length
	call	driver_serial_string

	; and exception address
	mov	rax,	qword [rsp + KERNEL_IDT_STRUCTURE_EXCEPTION.rip]
	mov	ebx,	STATIC_NUMBER_SYSTEM_hexadecimal
	xor	ecx,	ecx	; no prefix
	call	driver_serial_value

	; bochs, breakpoint
	xchg	bx,	bx

	; hold the door
	jmp	$

	; release value of CR2 register from stack
	add	rsp,	0x08

	; restore ogirinal registers
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; release value of exception ID and Error Code from stack
	add	rsp,	0x10

	; return from interrupt
	iretq

; align routine
align	0x08,	db	EMPTY
kernel_idt_spurious_interrupt:
	; return from interrupt
	iretq