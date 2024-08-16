;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	LIB_SYS
	%define	LIB_SYS

	%define	LIB_SYS_ERROR_undefinied		-1
	%define	LIB_SYS_ERROR_memory_no_enough		1
	%define	LIB_SYS_ERROR_file_not_found		2
	%define	LIB_SYS_ERROR_exec_not_executable	3

	%define	LIB_SYS_REQUEST_EXIT			0x00
	%define	LIB_SYS_REQUEST_FRAMEBUFFER		0x01
	%define	LIB_SYS_REQUEST_MEMORY_ALLOC		0x02
	%define	LIB_SYS_REQUEST_MEMORY_RELEASE		0x03
	%define	LIB_SYS_REQUEST_TASK_PID		0x04
	%define	LIB_SYS_REQUEST_DRIVER_MOUSE		0x05
	%define	LIB_SYS_REQUEST_STORAGE_READ_FILE	0x06
	%define	LIB_SYS_REQUEST_EXEC			0x07
	%define	LIB_SYS_REQUEST_IPC_SEND		0x08
	%define	LIB_SYS_REQUEST_IPC_RECEIVE		0x09
	%define	LIB_SYS_REQUEST_MEMORY_SHARE		0x0A
	%define	LIB_SYS_REQUEST_KEYBOARD		0x0B
	%define	LIB_SYS_REQUEST_TASK_STATUS		0x0C
	%define	LIB_SYS_REQUEST_STREAM_OUT		0x0D
	%define	LIB_SYS_REQUEST_STREAM_IN		0x0E
	%define	LIB_SYS_REQUEST_SERIAL_CHAR		0x0F
	%define	LIB_SYS_REQUEST_SERIAL_STRING		0x10
	%define	LIB_SYS_REQUEST_SERIAL_VALUE		0x11
	%define	LIB_SYS_REQUEST_TIME			0x12
	%define	LIB_SYS_REQUEST_STREAM_SET		0x13
	%define	LIB_SYS_REQUEST_STREAM_GET		0x14
	%define	LIB_SYS_REQUEST_SLEEP			0x15
	%define	LIB_SYS_REQUEST_UPTIME			0x16
	%define	LIB_SYS_REQUEST_STREAM_OUT_VALUE	0x17
	%define	LIB_SYS_REQUEST_TASK			0x18
	%define	LIB_SYS_REQUEST_MEMORY			0x19
	%define	LIB_SYS_REQUEST_THREAD			0x1A

	struc	LIB_SYS_STRUCTURE_MEMORY
		.total		resq	1
		.available	resq	1
		.SIZE:
	endstruc

	struc	LIB_SYS_STRUCTURE_FRAMEBUFFER
		.width_pixel	resw	1
		.height_pixel	resw	1
		.base_address	resq	1
		.scanline_byte	resq	1
		.pid		resq	1
		.SIZE:
	endstruc

	%define	LIB_SYS_STREAM_SIZE_byte		4096

	%define	LIB_SYS_STREAM_FLOW_out_to_parent_out	00000001b
	%define	LIB_SYS_STREAM_FLOW_out_to_parent_in	00000010b
	%define	LIB_SYS_STREAM_FLOW_out_to_in		00000100b

	%define LIB_SYS_STREAM_META_LENGTH_byte		0x08

	%define	LIB_SYS_STREAM_FLAG_data		00000001b
	%define	LIB_SYS_STREAM_FLAG_undefinied		00000010b
	%define	LIB_SYS_STREAM_FLAG_closed		00100000b
	%define	LIB_SYS_STREAM_FLAG_null		01000000b

	%define	LIB_SYS_STREAM_out			00000001b
	%define	LIB_SYS_STREAM_in			00000010b

	%define	STD_IPC_SIZE_byte		40

	%define	LIB_SYS_IPC_TYPE_ANY			0x00
	%define	LIB_SYS_IPC_TYPE_MOUSE			0x01
	%define	LIB_SYS_IPC_TYPE_KEYBOARD		0x02

	struc	STD_IPC_STRUCTURE
		.ttl		resq	1
		.source		resq	1
		.target		resq	1
		.data		resb	STD_IPC_SIZE_byte
		.SIZE:
	endstruc

	struc	STD_IPC_STRUCTURE_DEFAULT
		.type		resb	1
	endstruc

	struc	STD_IPC_STRUCTURE_KEYBOARD
		.type		resb	1
		.key		resw	1
	endstruc

	struc	STD_IPC_STRUCTURE_MOUSE
		.type		resb	1
		.status		resb	1
	endstruc

	%define	LIB_SYS_device_mouse_status_left_mouse_button	00000001b
	%define	LIB_SYS_device_mouse_status_right_mouse_button	00000010b

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

	%define	LIB_SYS_TASK_NAME_length	255

	struc	LIB_SYS_STRUCTURE_TASK
		.pid		resq	1
		.pid_parent	resq	1
		.sleep		resq	1
		.page		resq	1
		.flags		resw	1
		.length		resb	1
		.name		resb	LIB_SYS_TASK_NAME_length
		.SIZE:
	endstruc
%endif