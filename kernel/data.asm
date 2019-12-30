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

;===============================================================================
; STATIC
;===============================================================================
kernel_string_space					db	STATIC_ASCII_SPACE
kernel_string_new_line					db	STATIC_ASCII_NEW_LINE
kernel_string_dot					db	STATIC_ASCII_DOT

;===============================================================================
; DEBUG
;===============================================================================
kernel_debug_string_irq		db	"IRQ|"
kernel_debug_string_irq_end:
kernel_debug_string_tx_empty	db	"TX Empty", STATIC_ASCII_NEW_LINE
kernel_debug_string_tx_empty_end:
kernel_debug_string_rx		db	"RX|"
kernel_debug_string_rx_end:
kernel_debug_string_ipc_insert	db	"IPC+|"
kernel_debug_string_ipc_insert_end:
kernel_debug_string_ipc_remove	db	"IPC-|"
kernel_debug_string_ipc_remove_end:
kernel_debug_string_network	db	"Network|"
kernel_debug_string_network_end:
kernel_debug_string_ip		db	"IPv4|"
kernel_debug_string_ip_end:
kernel_debug_string_arp		db	"ARP|"
kernel_debug_string_arp_end:
kernel_debug_string_icmp	db	"ICMP|"
kernel_debug_string_icmp_end:
