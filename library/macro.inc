;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	MACRO
	%define MACRO

	; Bochs Enchanced Debugger: line break
	%macro	MACRO_DEBUF 0
		xchg	bx,	bx
	%endmacro

	%define	MACRO_PAGE_ALIGN_UP( value )( ((value) + ~STD_PAGE_mask) & STD_PAGE_mask )
	%define	MACRO_PAGE_ALIGN_DOWN( value )( (value) & ~(STD_PAGE_byte - 1) )

	%macro	MACRO_PAGE_ALIGN_UP_REGISTER 1
		add	%1,	~STD_PAGE_mask	; align up
		and	%1,	STD_PAGE_mask	; to page boundaries
	%endmacro
%endif
