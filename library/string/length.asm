;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

	;-----------------------------------------------------------------------
	; structures, definitions
	;-----------------------------------------------------------------------
	; global ---------------------------------------------------------------
	%include	"default.inc"	; not required, but nice to have
	;=======================================================================

;-------------------------------------------------------------------------------
; in:
;	rsi - pointer to string
; out:
;	rcx - length of string in bytes
lib_string_length:
	; preserve original register
	push	rsi

	; empty string as default
	mov	rcx,	STATIC_MAX_unsigned

.next:
	; length of current string
	inc	rcx

	; consider next byte
	inc	rsi

	; not end of string?
	cmp	byte [rsi - 1],	STATIC_ASCII_TERMINATOR
	jne	.next	; yes

.end:
	; restore original register
	pop	rsi

	; return from routine
	ret