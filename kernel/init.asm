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
	; library --------------------------------------------------------------
	%include	"library/elf.inc"
	; driver ---------------------------------------------------------------
	%include	"kernel/driver/serial.inc"
	; kernel ---------------------------------------------------------------
	%include	"kernel/config.inc"
	%include	"kernel/page.inc"
	%include	"kernel/task.inc"
	; kernel environment initialization routines ---------------------------
	%include	"kernel/init/acpi.inc"
	%include	"kernel/init/limine.inc"
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
	%include	"kernel/memory.asm"
	%include	"kernel/page.asm"
	; kernel environment initialization routines ---------------------------
	%include	"kernel/init/acpi.asm"
	%include	"kernel/init/memory.asm"
	%include	"kernel/init/page.asm"
	;=======================================================================

;-------------------------------------------------------------------------------
; void
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

	; parse ACPI tables
	call	kernel_init_acpi

	; recreate kernel's paging structures
	call	kernel_init_page

	; switch to new kernel paging array
	mov	rax,	~KERNEL_PAGE_mirror	; physical address
	and	rax,	qword [r8 + KERNEL_STRUCTURE.page_base_address]
	mov	cr3,	rax

	; set new stack pointer
	xor	rsp,	rsp

	; hold the door
	jmp	$