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

struc	KERNEL_IDT_STRUCTURE_HEADER
	.limit		resw	1
	.address	resq	1
endstruc