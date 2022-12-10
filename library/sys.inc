;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	SYS_ERROR_memory_no_enough	1
%define	SYS_ERROR_file_not_found	2
%define	SYS_ERROR_exec_not_executable	3

%define	SYS_REQUEST_FRAMEBUFFER		0x00

struc	SYS_STRUCTURE_FRAMEBUFFER
	.width_pixel	resw	1

	; align next label
	alignb	0x08

	.height_pixel	resw	1

	; align next label
	alignb	0x08

	.base_address	resq	1
	.scanline_byte	resq	1
	.pid		resq	1
	.SIZE:
endstruc