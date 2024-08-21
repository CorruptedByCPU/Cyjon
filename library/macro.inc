;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	MACRO
	%define MACRO

	; Bochs Enchanced Debugger: line break
	%macro	MACRO_DEBUF 0
		xchg	bx,	bx
	%endmacro

	%macro	MACRO_LOCK	2
			; preserve original register
			push	rax

			; lock value
			mov	al,	LOCK

		%%lock:
			; lock acquired?
			xchg	byte [%1 + %2],	al
			test	al,	al	; check
			jnz	%%lock	; no

			; restore original register
			pop	rax
	%endmacro
	%macro	MACRO_UNLOCK	2
		mov	byte [%1 + %2],	UNLOCK
	%endmacro

	%define	MACRO_PAGE_ALIGN_UP( value )( ((value) + ~STD_PAGE_mask) & STD_PAGE_mask )
	%define	MACRO_PAGE_ALIGN_DOWN( value )( (value) & STD_PAGE_mask )

	%macro	MACRO_PAGE_ALIGN_UP_REGISTER 1
		add	%1,	~STD_PAGE_mask	; align up
		and	%1,	STD_PAGE_mask	; to page boundaries
	%endmacro
%endif
