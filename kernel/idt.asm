;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;------------------------------------------------------------------------------
; in:
;	on stack:
;	- qword [rsp]		exception id
;	- qword [rsp + 0x08]	error code
kernel_idt_exception:
	; debug
	xchg	bx,	bx

	; hold the door
	jmp	$

	; return from routine
	ret

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_divide_by_zero:
	; no Error Code
	push	0
	; exception id
	push	0

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_debug:
	; no Error Code
	push	0
	; exception id
	push	1

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_breakpoint:
	; no Error Code
	push	0
	; exception id
	push	3

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_overflow:
	; no Error Code
	push	0
	; exception id
	push	4

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_boud_range_exceeded:
	; no Error Code
	push	0
	; exception id
	push	5

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_invalid_opcode:
	; no Error Code
	push	0
	; exception id
	push	6

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_device_not_available:
	; no Error Code
	push	0
	; exception id
	push	7

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_double_fault:
	; set exception id
	push	8

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_coprocessor_segment_overrun:
	; no Error Code
	push	0
	; exception id
	push	9

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_invalid_tss:
	; set exception id
	push	10

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_segment_not_present:
	; set exception id
	push	11

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_stack_segment_fault:
	; set exception id
	push	12

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_general_protection_fault:
	; set exception id
	push	13

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_page_fault:
	; set exception id
	push	14

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_x87_floating_point:
	; no Error Code
	push	0
	; exception id
	push	16

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_alignment_check:
	; exception id
	push	17

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_machine_check:
	; no Error Code
	push	0
	; exception id
	push	18

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_simd_floating_point:
	; no Error Code
	push	0
	; exception id
	push	19

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_virtualization:
	; no Error Code
	push	0
	; exception id
	push	20

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_control_protection:
	; exception id
	push	21

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_hypervisor_injection:
	; no Error Code
	push	0
	; exception id
	push	28

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_vmm_communication:
	; exception id
	push	29

	; continue
	jmp	kernel_idt_exception_entry

; align routine to full address
align	0x08,	db	0x00
kernel_idt_exception_security:
	; exception id
	push	30

	; continue
	jmp	kernel_idt_exception_entry

kernel_idt_exception_entry:
	; turn off Direction Flag
	cld

	; preserve original registers
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

	; put on the stack value of CR2 register
	mov	rax,	cr2
	push	rax

	; turn off Direction Flag
	cld

	; execute exception handler
	mov	rdi,	rsp
	call	kernel_idt_exception

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

	; return from the procedure
	iretq

; align routine to full address
align	0x08,	db	0x00
kernel_idt_interrupt:
	; accept current interrupt call
	call	kernel_lapic_accept

	; return from routine
	iretq

; align routine
align	0x08,	db	EMPTY
kernel_idt_interrupt_spurious:
	; return from interrupt
	iretq

;-------------------------------------------------------------------------------
; in:
;	rax - pointer to interrupt handler
;	bx - interrupt type
;	rcx - entry number
kernel_idt_mount:
	; preserve original registers
	push	rax
	push	rcx
	push	rdi

	; retirve pointer to IDT structure
	mov	rdi,	[r8 + KERNEL.idt_header + KERNEL_STRUCTURE_IDT_HEADER.base_address]

	; move pointer to entry
	shl	cx,	STD_MULTIPLE_BY_16_shift
	or	di,	cx

	; low bits of address (15...0)
	mov	word [rdi + KERNEL_STRUCTURE_IDT_ENTRY.base_low],	ax

	; middle bits of address (31...16)
	shr	rax,	STD_MOVE_HIGH_TO_AX_shift
	mov	word [rdi + KERNEL_STRUCTURE_IDT_ENTRY.base_middle],	ax

	; high bits of address (63...32)
	shr	rax,	STD_MOVE_HIGH_TO_AX_shift
	mov	dword [rdi + KERNEL_STRUCTURE_IDT_ENTRY.base_high],	eax

	; code descriptor of kernel environment
	mov	word [rdi + KERNEL_STRUCTURE_IDT_ENTRY.cs],	KERNEL_STRUCTURE_GDT.cs_ring0

	; type of interrupt
	mov	word [rdi + KERNEL_STRUCTURE_IDT_ENTRY.type],	bx

	; restore original registers
	pop	rdi
	pop	rcx
	pop	rax

	; return from routine
	ret