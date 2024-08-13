;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	KERNEL_TSS
	%define	KERNEL_TSS

	%define	KERNEL_TSS_OFFSET		0x06

	struc	KERNEL_STRUCTURE_TSS
		.reserved		resd	1
		.rsp0			resq	1
		.unused			resb	92;
		.SIZE:
	endstruc

	struc	KERNEL_STRUCTURE_TSS_ENTRY
		.limit_low		resw	1
		.base_low		resw	1
		.base_middle		resb	1
		.access			resb	1
		.flags_and_limit_high	resb	1
		.base_high		resb	1
		.base_64bit		resd	1
		.reserved		resd	1
	endstruc
%endif