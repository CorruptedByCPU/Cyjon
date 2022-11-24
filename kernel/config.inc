;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	KERNEL_name		"Cyjon"
%define	KERNEL_version		"0"
%define	KERNEL_revision		"1445"
%define	KERNEL_architecture	"x86_64"

%define	KERNEL_PAGE_high_half	0xFFFF800000000000

struc	KERNEL_STRUCTURE
	; variables of I/O APIC management functions
	.io_apic_base_address	resq	1

	; variables of LAPIC management functions
	.lapic_base_address	resq	1

	; variables of Memory management functions
	.memory_base_address	resq	1

	; variables of Page management functions
	.page_total		resq	1
	.page_available		resq	1
	.page_limit		resq	1

	; length of this structure in Bytes
	.SIZE:
endstruc