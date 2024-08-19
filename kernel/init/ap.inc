;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	KERNEL_INIT_AP
	%define	KERNEL_INIT_AP

	%define	KERNEL_INIT_AP_MSR_STAR		0xC0000081
	%define	KERNEL_INIT_AP_MSR_LSTAR	0xC0000082
	%define	KERNEL_INIT_AP_MSR_EFLAGS	0xC0000084
%endif