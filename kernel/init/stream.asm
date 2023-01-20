;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	r8 - pointer to kernel environment variables/routines
kernel_init_stream:
	; preserve original registers
	push	rcx
	push	rdi

	; assign space for stream cache
	mov	ecx,	((KERNEL_STREAM_limit * KERNEL_STREAM_STRUCTURE.SIZE) + ~STATIC_PAGE_mask) >> STATIC_PAGE_SIZE_shift
	call	kernel_memory_alloc

	; save it
	mov	qword [r8 + KERNEL_STRUCTURE.stream_base_address],	rdi

	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret