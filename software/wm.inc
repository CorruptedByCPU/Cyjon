;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%ifndef	WM
	%define	WM

	%define	WM_DESCRIPTOR_FLAG_active	1 << 0
	%define	WM_DESCRIPTOR_FLAG_hide		1 << 1

	%define	WM_IPC_TYPE_window		0
	%define	WM_IPC_TYPE_mouse		1
	%define	WM_IPC_TYPE_keyboard		2

	struc	WM_STRUCTURE_DESCRIPTOR
		.flags		resq	1
	endstruc

	struc	WM_STRUCTURE_IPC
		.type		resb	1
		.reserved	resb	7
		.SIZE:
	endstruc

	struc	WM_STRUCTURE_IPC_WINDOW_request
		.ipc		resb	WM_STRUCTURE_IPC.SIZE
		.width		resw	1
		.height		resw	1
	endstruc

	struc	WM_STRUCTURE_IPC_WINDOW_answer
		.ipc		resb	WM_STRUCTURE_IPC.SIZE
		.descriptor	resq	1
	endstruc
%endif