;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	r8 - pointer to kernel environment variables/routines
kernel_init_library:
	; preserve original registers
	push	rcx
	push	rdi

	; assign space for library list
	mov	rcx,	((KERNEL_LIBRARY_limit * KERNEL_LIBRARY_STRUCTURE.SIZE) + ~STATIC_PAGE_mask) >> STATIC_PAGE_SIZE_shift
	call	kernel_memory_alloc

	; save pointer to library list
	mov	qword [r8 + KERNEL_STRUCTURE.library_base_address],	rdi

	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret