;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	KERNEL_TASK_STACK_SIZE_byte	(STATIC_PAGE_SIZE_byte << STATIC_MULTIPLE_BY_2_shift)
%define	KERNEL_TASK_STACK_SIZE_page	(KERNEL_TASK_STACK_SIZE_byte >> STATIC_PAGE_SIZE_shift)
%define	KERNEL_TASK_STACK_address	(EMPTY - KERNEL_TASK_STACK_SIZE_byte)
%define	KERNEL_TASK_STACK_pointer	(EMPTY - STATIC_PAGE_SIZE_byte)	