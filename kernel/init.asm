;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

; 64 bit code
[bits 64]

; we are using Position Independed Code
default	rel

; main initialization procedure of kernel environment
global	init

	;-----------------------------------------------------------------------
	; structures, definitions
	;-----------------------------------------------------------------------
	; global ---------------------------------------------------------------
	%include	"default.inc"
	; limine structures/arrays ---------------------------------------------
	%include	"kernel/init/limine.inc"
	; kernel ---------------------------------------------------------------
	%include	"kernel/config.inc"
	; drivers --------------------------------------------------------------
	%include	"kernel/driver/serial.inc"
	;=======================================================================

; data of kernel
section	.data
	;-----------------------------------------------------------------------
	; variables, constants
	;-----------------------------------------------------------------------
	%include	"kernel/data.asm"
	;=======================================================================

; code of kernel
section .text
	;-----------------------------------------------------------------------
	; routines
	;-----------------------------------------------------------------------
	; drivers --------------------------------------------------------------
	%include	"kernel/driver/serial.asm"
	; kernel ---------------------------------------------------------------
	%include	"kernel/page.asm"
	; kernel environment initialization routines ---------------------------
	%include	"kernel/init/memory.asm"
	;=======================================================================

init:
	; configure failover output
	call	driver_serial

	; show kernel name, version, architecture and build time
	mov	rsi,	kernel_log_welcome
	call	driver_serial_string

	; framebuffer available?
	cmp	qword [kernel_limine_framebuffer_request + LIMINE_FRAMEBUFFER_REQUEST.response],	EMPTY
	jne	.framebuffer	; yes

	; framebuffer is not available
	mov	rsi,	kernel_log_framebuffer
	call	driver_serial_string

	; hold the door
	jmp	$

.framebuffer:
	; create binary memory map
	call	kernel_init_memory

	; hold the door
	jmp	$