;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	KERNEL_INIT_AP_MSR_STAR		0xC0000081
%define	KERNEL_INIT_AP_MSR_LSTAR	0xC0000082
%define	KERNEL_INIT_AP_MSR_EFLAGS	0xC0000084

%define	KERNEL_INIT_AP_STACK_pointer	KERNEL_TASK_STACK_pointer - 2048	; it's enough