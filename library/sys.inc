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