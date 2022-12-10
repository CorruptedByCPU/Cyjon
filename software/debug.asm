;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

	;-----------------------------------------------------------------------
	; structures, definitions
	;-----------------------------------------------------------------------
	; global ---------------------------------------------------------------
	%include	"default.inc"	; not required, but nice to have
	; library --------------------------------------------------------------
	%include	"library/sys.inc"
	;=======================================================================

; 64 bit code
[bits 64]

; main initialization procedure of kernel environment
global	entry

; information for linker
section	.data

; align table
align	0x08,	db	0x00
debug_framebuffer_descriptor:
	times SYS_STRUCTURE_FRAMEBUFFER.SIZE	db	EMPTY	

; information for linker
section .text
	;-----------------------------------------------------------------------
	; routines
	;-----------------------------------------------------------------------
	; library --------------------------------------------------------------
	%include	"library/sys.asm"
	;=======================================================================

entry:
	; request for framebuffer properties
	mov	eax,	SYS_REQUEST_FRAMEBUFFER
	mov	rdi,	debug_framebuffer_descriptor
	call	sys_request

	; hold the door
	jmp	$
