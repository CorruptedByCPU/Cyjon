;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	r8 - kernel environment variables/rountines base address
kernel_init_framebuffer:
	; preserve original registers
	push	rax
	push	rsi

	; framebuffer is available?
	cmp	qword [kernel_limine_framebuffer_request + LIMINE_FRAMEBUFFER_REQUEST.response],	EMPTY
	je	.error	; no

	; there is only 1 framebuffer available?
	mov	rsi,	qword [kernel_limine_framebuffer_request + LIMINE_FRAMEBUFFER_REQUEST.response]
	cmp	qword [rsi + LIMINE_FRAMEBUFFER_RESPONSE.framebuffer_count],	1
	je	.framebuffer	; yes

.error:
	; framebuffer is not available or undefinied
	mov	rsi,	kernel_log_framebuffer
	call	driver_serial_string

	; hold the door
	jmp	$

.framebuffer:
	; get pointer to framebuffer properties
	mov	rsi,	qword [rsi + LIMINE_FRAMEBUFFER_RESPONSE.framebuffer]
	mov	rsi,	qword [rsi]

	; store properties of framebuffer

	; base address
	mov	rax,	qword [rsi + LIMINE_FRAMEBUFFER.address]
	mov	qword [r8 + KERNEL_STRUCTURE.framebuffer_base_address],	rax

	; width in pixels
	mov	ax,	word [rsi + LIMINE_FRAMEBUFFER.width]
	mov	word [r8 + KERNEL_STRUCTURE.framebuffer_width_pixel],	ax

	; height in pixels
	mov	ax,	word [rsi + LIMINE_FRAMEBUFFER.height]
	mov	word [r8 + KERNEL_STRUCTURE.framebuffer_height_pixel],	ax

	; scanline in Bytes
	mov	eax,	dword [rsi + LIMINE_FRAMEBUFFER.pitch]
	mov	dword [r8 + KERNEL_STRUCTURE.framebuffer_scanline_byte],	eax

	; restore original registers
	pop	rsi
	pop	rax

	; return from routine
	ret