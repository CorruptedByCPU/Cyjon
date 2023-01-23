;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%ifndef	LIB_SYS
	%define	LIB_SYS

	%define	LIB_SYS_ERROR_undefinied		-1
	%define	LIB_SYS_ERROR_memory_no_enough		1
	%define	LIB_SYS_ERROR_file_not_found		2
	%define	LIB_SYS_ERROR_exec_not_executable	3

	%define	LIB_SYS_REQUEST_FRAMEBUFFER		0x00
	%define	LIB_SYS_REQUEST_MEMORY_ALLOC		0x01
	%define	LIB_SYS_REQUEST_MEMORY_RELEASE		0x02
	%define	LIB_SYS_REQUEST_TASK_PID		0x03
	%define	LIB_SYS_REQUEST_DRIVER_MOUSE		0x04
	%define	LIB_SYS_REQUEST_STORAGE_READ		0x05
	%define	LIB_SYS_REQUEST_EXEC			0x06
	%define	LIB_SYS_REQUEST_IPC_SEND		0x07
	%define	LIB_SYS_REQUEST_IPC_RECEIVE		0x08
	%define	LIB_SYS_REQUEST_MEMORY_SHARE		0x09
	%define	LIB_SYS_REQUEST_KEYBOARD		0x0A
	%define	LIB_SYS_REQUEST_TASK_STATUS		0x0B
	%define	LIB_SYS_REQUEST_STREAM_OUT		0x0C
	%define	LIB_SYS_REQUEST_STREAM_IN		0x0D

	struc	LIB_SYS_STRUCTURE_FRAMEBUFFER
		.width_pixel	resw	1
		.height_pixel	resw	1

		; align next label
		alignb	0x08

		.base_address	resq	1
		.scanline_byte	resq	1
		.pid		resq	1
		.SIZE:
	endstruc

	%define	LIB_SYS_STREAM_SIZE_byte		4096

	%define	LIB_SYS_STREAM_out_to_parent_out	00000001b
	%define	LIB_SYS_STREAM_out_to_parent_in		00000010b
	%define	LIB_SYS_STREAM_out_to_in		00000100b

	%define LIB_SYS_STREAM_META_LENGTH_byte		0x08

	%define	LIB_SYS_IPC_DATA_size_byte		40

	%define	LIB_SYS_IPC_TYPE_MOUSE			0x01
	%define	LIB_SYS_IPC_TYPE_KEYBOARD		0x02

	struc	LIB_SYS_STRUCTURE_IPC
		.ttl		resq	1
		.source		resq	1
		.target		resq	1
		.data		resb	LIB_SYS_IPC_DATA_size_byte
		.SIZE:
	endstruc

	struc	LIB_SYS_STRUCTURE_IPC_DEFAULT
		.type		resb	1
	endstruc

	struc	LIB_SYS_STRUCTURE_IPC_KEYBOARD
		.type		resb	1
		.key		resw	1
	endstruc

	struc	LIB_SYS_STRUCTURE_IPC_MOUSE
		.type		resb	1
		.status		resb	1
		.x		resw	1
		.y		resw	1
	endstruc

	%define	LIB_SYS_DRIVER_MOUSE_STATUS_left_mouse_button	00000001b
	%define	LIB_SYS_DRIVER_MOUSE_STATUS_right_mouse_button	00000010b

	struc	LIB_SYS_STRUCTURE_MOUSE
		.x		resw	1
		.y		resw	1
		.status		resb	1
	endstruc

	struc	LIB_SYS_STRUCTURE_STORAGE
		.address	resq	1
		.size_byte	resq	1
		.length		resb	1
		.name		resb	255
	endstruc

	extern	lib_sys_ipc_receive
	extern	lib_sys_serial_char

	[bits 64]

	default	rel

	global	entry
%endif