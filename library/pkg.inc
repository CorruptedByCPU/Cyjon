;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	LIB_PKG_align		16
%define	LIB_PKG_base		64
%define	LIB_PKG_length		4
%define	LIB_PKG_magic		"#PKG"
%define	LIB_PKG_name_limit	40
%define	LIB_PKG_shift		6

; this structure should be divisible by power of 2
struc	LIB_PKG_STRUCTURE
	.offset		resq	1
	.size		resq	1
	.length		resq	1
	.name		resb	LIB_PKG_name_limit
endstruc
