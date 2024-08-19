;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	LIB_VFS
	%define	LIB_VFS

	%define	LIB_VFS_length		4		; length of magic in Bytes
	%define	LIB_VFS_magic		0x53465623	; "#VFS"
	%define	LIB_VFS_block		STD_PAGE_byte
	%define	LIB_VFS_default		2		; default number of files in new directory (2 links)

	%define	LIB_VFS_NAME_limit	(254 - 1)

	struc	LIB_VFS_STRUCTURE
		.offset		resq	1
		.byte		resq	1
		.type		resb	1
		.name_length	resb	1
		.name		resb	LIB_VFS_NAME_limit + 1
		.SIZE:
	endstruc
%endif