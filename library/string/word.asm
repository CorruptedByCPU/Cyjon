;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

	;-----------------------------------------------------------------------
	; structures, definitions
	;-----------------------------------------------------------------------
	; global ---------------------------------------------------------------
	%include	"library/std.inc"	; not required, but nice to have
	;=======================================================================

;-------------------------------------------------------------------------------
;===============================================================================
; in:
;	rcx - length of string
;	rsi - pointer to string
; out:
;	rbx - length of string up to first separator
lib_string_word:
	; preserve original registers
	push	rcx

	; counter
	xor	ebx,	ebx

.search:
	; separator found?
	cmp	byte [rsi + rbx],	STATIC_ASCII_EXCLAMATION
	jb	.end	; yes
	cmp	byte [rsi + rbx],	STATIC_ASCII_TILDE
	ja	.end	; yes

	; word size
	inc	rbx

	; end of string?
	dec	rcx
	jnz	.search	; no

.end:
	; restore original registers
	pop	rcx

	; return from routine
	ret
