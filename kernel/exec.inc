;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	KERNEL_EXEC_DESCRIPTOR_offset	0x78

%define	KERNEL_EXEC_STACK_pointer	0x0000000000100000
%define	KERNEL_EXEC_STACK_address	KERNEL_EXEC_STACK_pointer - STATIC_PAGE_SIZE_byte

struc	KERNEL_EXEC_STRUCTURE
	.pid			resq	1
	.task_or_status		resq	1
	.SIZE:
endstruc

struc	KERNEL_EXEC_STRUCTURE_RETURN
	.rip		resq	1
	.cs		resq	1
	.eflags		resq	1
	.rsp		resq	1
	.ss		resq	1
	.SIZE:
endstruc