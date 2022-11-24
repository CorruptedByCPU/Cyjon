;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

struc	KERNEL_GDT_STRUCTURE
	.null			resq	1
	.cs_ring0		resq	1
	.ds_ring0		resq	1
	.empty			resq	1
	.ds_ring3		resq	1
	.cs_ring3		resq	1
	.tss:
endstruc

struc	KERNEL_GDT_STRUCTURE_HEADER
	.size			resw	1
	.address		resq	1
endstruc