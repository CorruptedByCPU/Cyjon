;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; GDT
;===============================================================================
; wyrównaj pozycję nagłówka do pełnego adresu
align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING
kernel_gdt_header					dw	KERNEL_PAGE_SIZE_byte
							dq	STATIC_EMPTY

; wyrównaj miejsca wskaźników do pełnego adresu
align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING
kernel_gdt_tss_bsp_selector				dw	STATIC_EMPTY
kernel_gdt_tss_cpu_selector				dw	STATIC_EMPTY

; wyrównaj pozycję tablicy do pełnego adresu
align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING
kernel_gdt_tss_table:
							dd	STATIC_EMPTY
							dq	KERNEL_STACK_pointer	; RSP0
					times	92	db	STATIC_EMPTY
kernel_gdt_tss_table_end:

;===============================================================================
; IDT
;===============================================================================
; wyrównaj pozycję nagłówka do pełnego adresu
align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING
kernel_idt_header:
							dw	KERNEL_PAGE_SIZE_byte
							dq	STATIC_EMPTY
