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
	times LIB_SYS_STRUCTURE_FRAMEBUFFER.SIZE	db	EMPTY	

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
	mov	eax,	LIB_SYS_REQUEST_FRAMEBUFFER
	mov	rdi,	debug_framebuffer_descriptor
	call	lib_sys_request

	;---
	; KERNEL buildin services
	;---

	; alloc memory space
	mov	eax,	LIB_SYS_REQUEST_MEMORY_ALLOC
	mov	edi,	4097	; Bytes
	call	lib_sys_request

	; release
	mov	rdi,	rax	; pointer to allocated space
	mov	eax,	LIB_SYS_REQUEST_MEMORY_RELEASE
	mov	esi,	4097	; Bytes
	call	lib_sys_request

	;---
	; libc
	;---

	; alloc memory space
	mov	edi,	1	; Byte
	call	malloc

	; release
	mov	rdi,	rax	; pointer to allocated space
	call	free

	; hold the door
	jmp	$
