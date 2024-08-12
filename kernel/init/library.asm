;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

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
	mov	qword [r8 + KERNEL.library_base_address],	rdi

	; assign memory space for binary memory map with same size as kernels
	mov	rcx,	qword [r8 + KERNEL.page_limit]
	shr	rcx,	STATIC_DIVIDE_BY_8_shift	; 8 pages per Byte
	add	rcx,	~STATIC_PAGE_mask	; align up to page boundaries
	shr	rcx,	STATIC_PAGE_SIZE_shift	; convert to pages
	call	kernel_memory_alloc

	; save pointer to library memory map
	mov	qword [r8 + KERNEL.library_memory_map_address],	rdi

	; fill memory map with available pages
	mov	rax,	STATIC_MAX_unsigned
	shl	rcx,	STATIC_MULTIPLE_BY_512_shift
	rep	stosq

	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret