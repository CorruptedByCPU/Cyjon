;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

string_error_framebuffer:
	db	"I See a Darkness.\n", STD_ASCII_TERMINATOR

string_error_memmap:
	db	"Houston, we have a problem.\n", STD_ASCII_TERMINATOR

string_error_rsdp:
	db	"Hello Darkness, My Old Friend.\n", STD_ASCII_TERMINATOR

string_error_kernel:
	db	"Whisky.\n", STD_ASCII_TERMINATOR

string_error_module:
	db	"Where Are My Testicles, Summer?\n", STD_ASCII_TERMINATOR

;-------------------------------------------------------------------------------
; void
kernel_init_limine:
	; preserve original registers
	push	rdi

	;----------------------------------------------------------------------

	; properties of framebuffer request
	mov	rdi,	qword [kernel_limine_framebuffer_request + LIMINE_FRAMEBUFFER_REQUEST.response]

	; linear framebuffer is available?
	test	rdi,	rdi
	jz	.error_framebuffer	; no

	; at least 1 frame buffer available?
	cmp	qword [rdi + LIMINE_FRAMEBUFFER_RESPONSE.framebuffer_count],	EMPTY
	je	.error_framebuffer	; nothing

	; properties of framebuffer response
	mov	rdi,	qword [rdi + LIMINE_FRAMEBUFFER_RESPONSE.framebuffers]
	mov	rdi,	qword [rdi + INIT]	; properties of first framebuffer

	; with 32 bits per pixel?
	cmp	word [rdi + LIMINE_FRAMEBUFFER.bpp],	STD_VIDEO_DEPTH_bit
	jne	.error_framebuffer	; different

	;----------------------------------------------------------------------

	; properties of memory map request
	mov	rdi,	qword [kernel_limine_memmap_request + LIMINE_MEMMAP_REQUEST.response]

	; memory map provided?
	test	rdi,	rdi
	jz	.error_memmap	; no

	; no entries?
	cmp	qword [rdi + LIMINE_MEMMAP_RESPONSE.entry_count],	EMPTY
	je	.error_memmap	; yep

	;----------------------------------------------------------------------

	; properties of RSDP request
	mov	rdi,	qword [kernel_limine_rsdp_request + LIMINE_RSDP_REQUEST.response]

	; RSDP pointer available?
	test	rdi,	rdi
	jz	.error_rsdp	; no

	; located?
	cmp	qword [rdi + LIMINE_RSDP_RESPONSE.address],	EMPTY
	je	.error_rsdp	; nothing there

	;----------------------------------------------------------------------

	; information about kernel?
	cmp	qword [kernel_limine_kernel_file_request + LIMINE_KERNEL_FILE_REQUEST.response],	EMPTY
	je	.error_kernel	; no
	cmp	qword [kernel_limine_kernel_address_request + LIMINE_KERNEL_FILE_ADDRESS_REQUEST.response],	EMPTY
	je	.error_kernel	; also no

	;----------------------------------------------------------------------

	; properties of module request
	mov	rdi,	qword [kernel_limine_module_request + LIMINE_MODULE_REQUEST.response]

	; modules attached?
	test	rdi,	rdi
	jz	.error_module	; no

	; at least 1?
	cmp	qword [rdi + LIMINE_MODULE_RESPONSE.module_count],	EMPTY
	je	.error_module	; nope

	; restore original registers
	pop	rdi

	; return from routine
	ret

.error_framebuffer:
	; show error
	mov	rdi,	string_error_framebuffer
	call	kernel_log

	; hold the door
	jmp	$

.error_memmap:
	; show error
	mov	rdi,	string_error_memmap
	call	kernel_log

	; hold the door
	jmp	$

.error_rsdp:
	; show error
	mov	rdi,	string_error_rsdp
	call	kernel_log

	; hold the door
	jmp	$

.error_kernel:
	; show error
	mov	rdi,	string_error_kernel
	call	kernel_log

	; hold the door
	jmp	$

.error_module:
	; show error
	mov	rdi,	string_error_module
	call	kernel_log

	; hold the door
	jmp	$