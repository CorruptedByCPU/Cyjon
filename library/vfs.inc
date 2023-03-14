;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	LIB_VFS

%define	LIB_VFS_align		16
%define	LIB_VFS_base		64
%define	LIB_VFS_length		4
%define	LIB_VFS_magic		"#VFS"
%define	LIB_VFS_name_limit	39
%define	LIB_VFS_shift		6

%define	LIB_VFS_TYPE_default	0

; this structure should be divisible by power of 2
struc	LIB_VFS_STRUCTURE
	.offset		resq	1
	.size		resq	1
	.length		resq	1
	.name		resb	LIB_VFS_name_limit + 1
	.SIZE:
endstruc