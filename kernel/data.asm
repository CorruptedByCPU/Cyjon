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

kernel_idt_exception_string_unknown			db	STATIC_ASCII_NEW_LINE, "{UNKNOWN CPU EXCEPTION}", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_divide_by_zero_error	db	STATIC_ASCII_NEW_LINE, "Divide-by-zero Error", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_debug			db	STATIC_ASCII_NEW_LINE, "Debug", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_breakpoint			db	STATIC_ASCII_NEW_LINE, "Breakpoint", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_overflow			db	STATIC_ASCII_NEW_LINE, "Overflow", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_boud_range_exceeded		db	STATIC_ASCII_NEW_LINE, "Bound Range Exceeded", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_invalid_opcode		db	STATIC_ASCII_NEW_LINE, "Invalid Opcode", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_device_not_available	db	STATIC_ASCII_NEW_LINE, "Device Not Available", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_double_fault		db	STATIC_ASCII_NEW_LINE, "Double Fault", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_coprocessor_sefment_overrun	db	STATIC_ASCII_NEW_LINE, "Coprocessor Segment Overrun", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_invalid_tss			db	STATIC_ASCII_NEW_LINE, "Invalid TSS", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_segment_not_present		db	STATIC_ASCII_NEW_LINE, "Segment Not Present", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_stack_segment_fault		db	STATIC_ASCII_NEW_LINE, "Stack-Segment Fault", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_general_protection_fault	db	STATIC_ASCII_NEW_LINE, "General Protection Fault", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_page_fault			db	STATIC_ASCII_NEW_LINE, "Page Fault", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_x87_floating_point		db	STATIC_ASCII_NEW_LINE, "x87 Floating-Point", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_alignment_check		db	STATIC_ASCII_NEW_LINE, "Alignment Check", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_machine_check		db	STATIC_ASCII_NEW_LINE, "Machine Check", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_simd_floating_point		db	STATIC_ASCII_NEW_LINE, "SIMD Floating-Point", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_virtualization		db	STATIC_ASCII_NEW_LINE, "Virtualization", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_control_protection		db	STATIC_ASCII_NEW_LINE, "Control Protection", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_hypervisor_injection	db	STATIC_ASCII_NEW_LINE, "Hypervisor Injection", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_vmm_communication		db	STATIC_ASCII_NEW_LINE, "VMM Communication", " at 0x", STATIC_ASCII_TERMINATOR
kernel_idt_exception_string_security			db	STATIC_ASCII_NEW_LINE, "Security", " at 0x", STATIC_ASCII_TERMINATOR

; align table
align	0x08,	db	0x00
kernel_idt_exception_string:
	dq	kernel_idt_exception_string_divide_by_zero_error
	dq	kernel_idt_exception_string_debug
	dq	kernel_idt_exception_string_unknown
	dq	kernel_idt_exception_string_breakpoint
	dq	kernel_idt_exception_string_overflow
	dq	kernel_idt_exception_string_boud_range_exceeded
	dq	kernel_idt_exception_string_invalid_opcode
	dq	kernel_idt_exception_string_device_not_available
	dq	kernel_idt_exception_string_double_fault
	dq	kernel_idt_exception_string_coprocessor_sefment_overrun
	dq	kernel_idt_exception_string_invalid_tss
	dq	kernel_idt_exception_string_segment_not_present
	dq	kernel_idt_exception_string_stack_segment_fault
	dq	kernel_idt_exception_string_general_protection_fault
	dq	kernel_idt_exception_string_page_fault
	dq	kernel_idt_exception_string_unknown
	dq	kernel_idt_exception_string_x87_floating_point
	dq	kernel_idt_exception_string_alignment_check
	dq	kernel_idt_exception_string_simd_floating_point
	dq	kernel_idt_exception_string_virtualization
	dq	kernel_idt_exception_string_control_protection
	dq	kernel_idt_exception_string_unknown
	dq	kernel_idt_exception_string_unknown
	dq	kernel_idt_exception_string_unknown
	dq	kernel_idt_exception_string_unknown
	dq	kernel_idt_exception_string_unknown
	dq	kernel_idt_exception_string_unknown
	dq	kernel_idt_exception_string_hypervisor_injection
	dq	kernel_idt_exception_string_vmm_communication
	dq	kernel_idt_exception_string_security
	dq	kernel_idt_exception_string_unknown