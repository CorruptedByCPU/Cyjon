;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	LIB_PKG_base		64
%define	LIB_PKG_align		16
%define	LIB_PKG_name_limit	40

struc	LIB_PKG_STRUCTURE
	.offset		resq	1
	.size		resq	1
	.length		resq	1
	.name		resb	LIB_PKG_name_limit
endstruc
