;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	KERNEL_GDT
	%define	KERNEL_GDT

	%define	KERNEL_GDT_FIELD_ACCESS_read_or_write		(1 << 1)
	%define	KERNEL_GDT_FIELD_ACCESS_executable		(1 << 3)
	%define	KERNEL_GDT_FIELD_ACCESS_code_or_data		(1 << 4)
	%define	KERNEL_GDT_FIELD_ACCESS_level_1			(1 << 5)
	%define	KERNEL_GDT_FIELD_ACCESS_level_2			(1 << 6)
	%define	KERNEL_GDT_FIELD_ACCESS_level_3			(KERNEL_GDT_FIELD_ACCESS_level_1 | KERNEL_GDT_FIELD_ACCESS_level_2)
	%define	KERNEL_GDT_FIELD_ACCESS_present			(1 << 7)

	%define	KERNEL_GDT_FIELD_FLAGS_long_mode		(1 << 1)

	struc	KERNEL_STRUCTURE_GDT
		.null			resq	1
		.cs_ring0		resq	1
		.ss_ring0		resq	1
		.empty			resq	1
		.ss_ring3		resq	1
		.cs_ring3		resq	1
		.tss:
	endstruc

	struc	KERNEL_STRUCTURE_GDT_ENTRY
		.limit_low		resw	1
		.base_low		resw	1
		.base_middle		resb	1
		.access			resb	1
		.flags_and_limit_high	resb	1
		.base_high		resb	1
	endstruc

	struc	KERNEL_STRUCTURE_GDT_HEADER
		.limit			resw	1
		.base_address		resq	1
		.SIZE:
	endstruc
%endif