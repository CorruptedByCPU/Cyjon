;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%define	LIB_VFS

%define	LIB_VFS_align			16
%define	LIB_VFS_base			64
%define	LIB_VFS_length			4
%define	LIB_VFS_magic			"#VFS"
%define	LIB_VFS_name_limit		42
%define	LIB_VFS_shift			6
%define	LIB_VFS_default			2

%define	LIB_VFS_TYPE_regular_file	00000001b
%define	LIB_VFS_TYPE_directory		00000010b
%define	LIB_VFS_TYPE_symbolic_link	00000100b
%define	LIB_VFS_TYPE_shared_object	00001000b

%define	LIB_VFS_MODE_user_executable	0x0000000000000001

; this structure should be divisible by power of 2
struc	LIB_VFS_STRUCTURE
	.offset		resq	1
	.size		resq	1
	.length		resw	1
	.mode		resw	1
	.type		resb	1
	.name		resb	LIB_VFS_name_limit + 1
	.SIZE:
endstruc