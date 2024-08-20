;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_library:
	; preserve original registers
	push	rax
	push	rcx
	push	rdi

	; prepare area for library entries
	mov	rcx,	MACRO_PAGE_ALIGN_UP( KERNEL_LIBRARY_limit * KERNEL_LIBRARY_STRUCTURE.SIZE ) >> STD_SHIFT_PAGE
	call	kernel_memory_alloc

	; preserve pointer inside KERNEL environment
	mov	qword [r8 + KERNEL.library_base_address],	rdi

	; prepare area for memory map of libraries with size same as kernels memory map
	mov	rcx,	qword [r8 + KERNEL.page_limit]
	shr	rcx,	STD_SHIFT_8
	inc	rcx	; semaphore
	MACRO_PAGE_ALIGN_UP_REGISTER	rcx
	shr	rcx,	STD_SHIFT_PAGE
	call	kernel_memory_alloc

	; preserve pointer inside KERNEL environment
	mov	qword [r8 + KERNEL.library_map_address],	rdi

	; initialize library memory map
	xor	eax,	eax
	mov	rcx,	qword [r8 + KERNEL.page_limit]
	call	kernel_memory_dispose

	; restore original registers
	pop	rdi
	pop	rcx
	pop	rax

	; return from routine
	ret