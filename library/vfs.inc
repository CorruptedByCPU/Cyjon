;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	LIB_VFS
	%define	LIB_VFS

	%define	LIB_VFS_length		4
	%define	LIB_VFS_magic		"#VFS"
	%define	LIB_VFS_block		STD_PAGE_byte
	%define	LIB_VFS_default		2

	%define	LIB_VFS_NAME_limit	(254 - 17)

	struc	LIB_VFS_STRUCTURE
		.offset		resq	1
		.byte		resq	1
		.type		resb	1
		.name_length	resb	1
		.name		resb	LIB_VFS_NAME_limit + 1
		.SIZE:
	endstruc
%endif