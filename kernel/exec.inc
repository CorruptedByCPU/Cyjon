;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	KERNEL_EXEC_DESCRIPTOR_offset		0x78

%define	KERNEL_EXEC_BASE_address		0x0000000000100000

; whole 223th entry of PML4 table, for easier thread closing
%define	KERNEL_EXEC_STACK_SIZE_page		STATIC_PAGE_SIZE_page << STATIC_MULTIPLE_BY_2_shift
%define	KERNEL_EXEC_STACK_pointer		0x0000700000000000
%define	KERNEL_EXEC_STACK_address		KERNEL_EXEC_STACK_pointer - (KERNEL_EXEC_STACK_SIZE_page << STATIC_PAGE_SIZE_shift)

%define	KERNEL_EXEC_STACK_OFFSET_registers	0x78

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
