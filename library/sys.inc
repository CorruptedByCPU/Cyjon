;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	LIB_SYS

%define	LIB_SYS_ERROR_memory_no_enough		1
%define	LIB_SYS_ERROR_file_not_found		2
%define	LIB_SYS_ERROR_exec_not_executable	3

%define	LIB_SYS_REQUEST_FRAMEBUFFER		0x00
%define	LIB_SYS_REQUEST_MEMORY_ALLOC		0x01
%define	LIB_SYS_REQUEST_MEMORY_RELEASE		0x02
%define	LIB_SYS_REQUEST_TASK_PID		0x03
%define	LIB_SYS_REQUEST_DRIVER_MOUSE		0x04
%define	LIB_SYS_REQUEST_STORAGE_READ		0x05

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