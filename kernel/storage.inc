;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	KERNEL_STORAGE_limit			1

%define	KERNEL_STORAGE_TYPE_memory		00000001b

%define	KERNEL_STORAGE_FILE_TYPE_regular	00000001b

%define	KERNEL_STORAGE_STRUCTURE_SIZE_shift	6

; this structure should be divisible by power of 2
struc	KERNEL_STORAGE_STRUCTURE
	.device_type		resb	1

	; align next label
	alignb	0x08

	.device_blocks		resq	1
	.device_first_block	resq	1
	.storage_file		resq	1
	.storage_read		resq	1

	; align next label
	alignb	0x18

	.SIZE:
endstruc

; this structure should be divisible by 8
struc	KERNEL_STORAGE_STRUCTURE_FILE
	.id			resq	1
	.size_byte		resq	1
	.SIZE:
endstruc