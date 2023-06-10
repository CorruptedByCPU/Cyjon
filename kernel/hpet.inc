;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%ifndef	KERNEL_HPET
	%define KERNEL_HPET

	%define	KERNEL_HPET_TIMER_UPTIME_irq	0x08
	%define	KERNEL_HPET_IO_APIC_register	KERNEL_IO_APIC_iowin + (KERNEL_HPET_TIMER_UPTIME_irq * 0x02)

	%define	KERNEL_HPET_TIMER_offset	0x0100

	struc KERNEL_HPET_STRUCTURE_REGISTER
		.general_capabilities_and_id	resq	1
		.reserved_0			resq	1
		.general_configuration		resq	1
		.reserved_1			resq	1
		.general_interrupt_status	resq	1
		.reserved_2			resq	25
		.main_counter_value		resq	1
		.reserved_3			resq	1
	endstruc

	struc KERNEL_HPET_STRUCTURE_TIMER
		.configuration_and_capabilities	resq	1
		.comparator			resq	1
		.fsb_interrupt_route		resq	1
		.reserved			resq	1
		.SIZE:
	endstruc
%endif