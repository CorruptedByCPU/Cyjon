;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

kernel_environment_base_address	dq	EMPTY

; align table
align	0x08,	db	0x00
kernel_gdt_header		dw	STATIC_PAGE_SIZE_byte
				dq	EMPTY

; align table
align	0x08,	db	0x00
kernel_idt_header		dw	STATIC_PAGE_SIZE_byte
				dq	EMPTY

; align table
align	0x08,	db	0x00
kernel_tss_header		dd	EMPTY
				dq	KERNEL_TASK_STACK_pointer	; rsp0
		times 92	db	EMPTY
kernel_tss_header_end: