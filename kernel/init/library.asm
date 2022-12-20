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

	; assign space for memory map of library space
	call	kernel_memory_alloc_page
	or	rdi,	qword [kernel_page_mirror]

	; save pointer to library memory map
	mov	qword [r8 + KERNEL_STRUCTURE.library_memory_map_address],	rdi

	; fill memory map with available pages
	mov	al,	STATIC_MAX_unsigned
	mov	rcx,	KERNEL_EXEC_BASE_address
	shr	rcx,	STATIC_PAGE_SIZE_shift	; convert space to pages
	shr	rcx,	STATIC_DIVIDE_BY_8_shift	; convert pages to Bytes
	rep	stosb

	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret