;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	KERNEL_TASK_EFLAGS_cf		000000000000000000000001b
%define	KERNEL_TASK_EFLAGS_zf		000000000000000001000000b
%define	KERNEL_TASK_EFLAGS_if		000000000000001000000000b
%define	KERNEL_TASK_EFLAGS_df		000000000000010000000000b
%define	KERNEL_TASK_EFLAGS_default	KERNEL_TASK_EFLAGS_if

%define	KERNEL_TASK_FLAG_active		0000000000000001b
%define	KERNEL_TASK_FLAG_closed		0000000000000010b
%define	KERNEL_TASK_FLAG_daemon		0000000000000100b
%define	KERNEL_TASK_FLAG_exec		0000000000001000b
%define	KERNEL_TASK_FLAG_secured	0000000000010000b
%define	KERNEL_TASK_FLAG_thread		0000000000100000b
%define	KERNEL_TASK_FLAG_stream_in	0000000001000000b
%define	KERNEL_TASK_FLAG_stream_out	0000000010000000b
%define	KERNEL_TASK_FLAG_sleep		0000000100000000b
%define	KERNEL_TASK_FLAG_init		0000010000000000b

%define	KERNEL_TASK_FLAG_secured_bit	4

%define	KERNEL_TASK_irq			0x20

%define	KERNEL_TASK_limit		32
%define	KERNEL_TASK_NAME_limit		255

%define	KERNEL_TASK_STACK_SIZE_byte	(STATIC_PAGE_SIZE_byte << STATIC_MULTIPLE_BY_2_shift)
%define	KERNEL_TASK_STACK_SIZE_page	(KERNEL_TASK_STACK_SIZE_byte >> STATIC_PAGE_SIZE_shift)
%define	KERNEL_TASK_STACK_address	(EMPTY - KERNEL_TASK_STACK_SIZE_byte)
%define	KERNEL_TASK_STACK_pointer	(EMPTY - STATIC_PAGE_SIZE_byte)

struc	KERNEL_TASK_STRUCTURE
	.cr3		resq	1
	.rsp		resq	1
	.pid		resq	1
	.pid_parent	resq	1
	.sleep		resq	1
	.memory_map	resq	1
	.stream_in	resq	1
	.stream_out	resq	1
	.flags		resw	1
	.length		resb	1
	.name		resb	KERNEL_TASK_NAME_limit + 1
	.SIZE:
endstruc