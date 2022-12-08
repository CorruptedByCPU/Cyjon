;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

struc	KERNEL_EXEC_STRUCTURE
	.pid			resq	1
	.task_and_status	resq	1
	.SIZE:
endstruc