;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

	;-----------------------------------------------------------------------
	; structures, definitions
	;-----------------------------------------------------------------------
	; global ---------------------------------------------------------------
	%include	"default.inc"	; not required, but nice to have
	;=======================================================================

; 64 bit code
[bits 64]

; we are using Position Independed Code
default	rel

;-------------------------------------------------------------------------------
; in:
;	rcx - length to compare
;	rsi - pointer to first string
;	rdi - pointer to second string
; out:
;	CF - if doesn't match
lib_string_compare:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi
	push	rdi

.loop:
	; load first character from string
	lodsb

	; characters equal?
	cmp	al,	byte [rdi]
	jne	.error	; no

	; move pointer to next character
	inc	rdi

	; strings match?
	dec	rcx
	jnz	.loop	; not, yet

	; they match
	clc
	jmp	.end

.error:
	; doesn't match
	stc

.end:
	; restore original registers
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; return from routine
	ret