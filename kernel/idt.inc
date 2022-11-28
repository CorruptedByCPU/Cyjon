;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

KERNEL_IDT_IRQ_offset		equ	0x20

KERNEL_IDT_TYPE_exception	equ	0x8E00
KERNEL_IDT_TYPE_irq		equ	0x8F00
KERNEL_IDT_TYPE_isr		equ	0xEF00

struc	KERNEL_IDT_STRUCTURE_ENTRY
	.address_low	resw	1
	.cs		resw	1
	.type		resw	1
	.address_middle	resw	1
	.address_high	resd	1
	.reserved	resd	1
endstruc

struc	KERNEL_IDT_STRUCTURE_EXCEPTION
	.cr2		resq	1
	.r15		resq	1
	.r14		resq	1
	.r13		resq	1
	.r12		resq	1
	.r11		resq	1
	.r10		resq	1
	.r9		resq	1
	.r8		resq	1
	.rbp		resq	1
	.rdi		resq	1
	.rsi		resq	1
	.rdx		resq	1
	.rcx		resq	1
	.rbx		resq	1
	.rax		resq	1
	.id		resq	1
	.error_code	resq	1
	.rip		resq	1
	.cs		resq	1
	.eflags		resq	1
	.rsp		resq	1
	.ss		resq	1
endstruc

struc	KERNEL_IDT_STRUCTURE_HEADER
	.limit		resw	1
	.address	resq	1
endstruc