;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	KERNEL_STORAGE_limit			1

%define	KERNEL_STORAGE_TYPE_memory		00000001b

%define	KERNEL_STORAGE_FLAG_active		00000001b
%define	KERNEL_STORAGE_FLAG_used		10000000b

%define	KERNEL_STORAGE_FILE_TYPE_regular	00000001b

%define	KERNEL_STORAGE_SIZE_shift		6

; this structure should be divisible by power of 2
struc	KERNEL_STORAGE_STRUCTURE
	.flags			resb	1

	; align next label
	alignb	0x04

	.device_type		resb	1

	; align next label
	alignb	0x04

	.device_blocks		resq	1
	.device_first_block	resq	1
	.storage_file		resq	1
	.storage_read		resq	1

	; align next label
	alignb	0x40

	.SIZE:
endstruc

; this structure should be divisible by 8
struc	KERNEL_STORAGE_STRUCTURE_FILE
	.id			resq	1
	.type			resb	1

	; align next label
	alignb	0x08

	.size_byte		resq	1
	.SIZE:
endstruc