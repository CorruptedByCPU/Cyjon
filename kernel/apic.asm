;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_APIC_ID_register			equ	0x0020	; APIC ID
KERNEL_APIC_TP_register			equ	0x0080	; Task Priority Register
KERNEL_APIC_EOI_register		equ	0x00B0
KERNEL_APIC_LD_register			equ	0x00D0	; Logical Destination Register
KERNEL_APIC_LD_FLAG_target_cpu		equ	0x01000000
KERNEL_APIC_DF_register			equ	0x00E0	; Destination Format Register
KERNEL_APIC_DF_FLAG_flat_mode		equ	0xFFFFFFFF
KERNEL_APIC_SIV_register		equ	0x00F0	; Spurious Interrupt Vector Register
KERNEL_APIC_SIV_FLAG_enable_apic	equ	00000000000000000000000100000000b
KERNEL_APIC_SIV_FLAG_spurious_vector	equ	00000000000000000000000011111111b
KERNEL_APIC_ICL_register		equ	0x0300	; Interrupt Command Register (bits 0..31)
KERNEL_APIC_ICL_COMMAND_COMPLETE_bit	equ	12
KERNEL_APIC_ICH_register		equ	0x0310	; Interrupt Command Register (bits 32..63)
KERNEL_APIC_LVT_TR_register		equ	0x0320	; Local Vector Timer - Timer Register
KERNEL_APIC_LVT_TR_FLAG_mask_interrupts	equ	00000000000000010000000000000000b
KERNEL_APIC_TICR_register		equ	0x0380
KERNEL_APIC_TDC_register		equ	0x03E0
KERNEL_APIC_TDC_divide_by_1		equ	0x0B
KERNEL_APIC_TDC_divide_by_16		equ	0x03

KERNEL_APIC_IRQ_number			equ	0x20

kernel_apic_base_address		dq	STATIC_EMPTY
kernel_apic_size			dq	STATIC_EMPTY

kernel_apic_count			db	STATIC_EMPTY

kernel_apic_id_table	times	0x0100	db	STATIC_EMPTY

;===============================================================================
; wyjście:
;	rax - identyfikator procesora logicznego
kernel_apic_id_get:
	; macro
	macro_apic_id_get

	; powrót z procedury
	ret

	macro_debug	"kernel_apic_id_get"
