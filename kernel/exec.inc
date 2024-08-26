;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	KERNEL_EXEC
	%define	KERNEL_EXEC

	%define	KERNEL_EXEC_BASE_address		0x0000000000100000

	struc	KERNEL_STRUCTURE_EXEC_TMP
		.level			resb	1
		.socket			resq	1
		.properties		resb	KERNEL_STRUCTURE_VFS_PROPERTIES.SIZE
		.task			resq	1
		.workbench_address	resq	1
		.base_address		resq	1
		.page			resq	1
		.stack			resq	1
		.stack_byte		resq	1
		.path			resq	1
		.path_length		resq	1
		.SIZE:
	endstruc
%endif