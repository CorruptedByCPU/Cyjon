;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	KERNEL_LAPIC
	%define	KERNEL_LAPIC
	
	%define	KERNEL_LAPIC_Hz					32768

	%define	KERNEL_LAPIC_IRQ_number				0x20
	%define	KERNEL_LAPIC_INIT_READY_bit			12
	%define	KERNEL_LAPIC_DF_FLAG_flat_mode			0xFFFFFFFF
	%define	KERNEL_LAPIC_LD_FLAG_target_cpu			0x01000000
	%define	KERNEL_LAPIC_SIV_FLAG_enable_apic		00000000000000000000000100000000b
	%define	KERNEL_LAPIC_SIV_FLAG_spurious_vector3		00000000000000000000000011111111b	; int 0xFF
	%define	KERNEL_LAPIC_LVT_TR_FLAG_mask_interrupts	00000000000000010000000000000000b
	%define	KERNEL_LAPIC_TDC_divide_by_1			00000000000000000000000000000111b

	struc	KERNEL_STRUCTURE_LAPIC
		.reserved_0	resb	32
		.id		resd	1
		.reserved_1	resb	92
		.tp		resd	1
		.reserved_2	resb	44
		.eoi		resd	1
		.reserved_3	resb	28
		.ld		resd	1
		.reserved_4	resb	12
		.df		resd	1
		.reserved_5	resb	12
		.siv		resd	1
		.reserved_6	resb	524
		.icl		resd	1
		.reserved_7	resb	12
		.ich		resd	1
		.reserved_8	resb	12
		.lvt		resd	1
		.reserved_9	resb	92
		.tic		resd	1
		.reserved_A	resb	12
		.tcc		resd	1
		.reserved_B	resb	76
		.tdc		resd	1
	endstruc
%endif