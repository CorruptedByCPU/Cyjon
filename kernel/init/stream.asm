;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_stream:
	; preserve original registers
	push	rcx
	push	rdi

	; prepare area for streams
	mov	ecx,	MACRO_PAGE_ALIGN_UP( KERNEL_STREAM_limit * KERNEL_STRUCTURE_STREAM.SIZE ) >> STD_SHIFT_PAGE
	call	kernel_memory_alloc
	mov	qword [r8 + KERNEL.stream_base_address],	rdi

	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret