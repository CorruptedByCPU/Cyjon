;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	KERNEL_TASK
	%define	KERNEL_TASK

	%define	KERNEL_TASK_EFLAGS_cf		000000000000000000000001b
	%define	KERNEL_TASK_EFLAGS_df		000000000000010000000000b
	%define	KERNEL_TASK_EFLAGS_if		000000000000001000000000b
	%define	KERNEL_TASK_EFLAGS_zf		000000000000000001000000b
	%define	KERNEL_TASK_EFLAGS_default	KERNEL_TASK_EFLAGS_if

	%define	KERNEL_TASK_FLAG_active		0000000000000001b
	%define	KERNEL_TASK_FLAG_exec		0000000000000010b
	%define	KERNEL_TASK_FLAG_close		0000000000000100b
	%define	KERNEL_TASK_FLAG_module		0000000000001000b
	%define	KERNEL_TASK_FLAG_thread		0000000000010000b
	%define	KERNEL_TASK_FLAG_sleep		0000000000100000b
	%define	KERNEL_TASK_FLAG_init		0100000000000000b
	%define	KERNEL_TASK_FLAG_secured	1000000000000000b

	%define	KERNEL_TASK_limit		(8192 / KERNEL_STRUCTURE_TASK.SIZE)	; hard limit

; TODO, remove me after refactoring
%define	KERNEL_TASK_irq			0x20

	%define	KERNEL_TASK_NAME_limit		254

	%define	KERNEL_TASK_STACK_pointer	KERNEL_LIBRARY_base_address
	%define	KERNEL_TASK_STACK_limit		STD_PAGE_byte

	struc	KERNEL_STRUCTURE_TASK
		.cr3		resq	1
		.rsp		resq	1
		.pid		resq	1
		.pid_parent	resq	1
		.sleep		resq	1
		.storage	resq	1
		.directory	resq	1
		.page		resq	1	; amount of pages assigned to process
		.page_type	resb	1
		.stack		resq	1	; size of stack in Pages
		.time		resq	1
		.time_previous	resq	1
		.stream_in	resq	1
		.stream_out	resq	1
		.memory_map	resq	1
		.flags		resw	1
		.name_length	resb	1
		.name		resb	KERNEL_TASK_NAME_limit + 1
		.SIZE:
	endstruc
%endif