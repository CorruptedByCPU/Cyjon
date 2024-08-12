;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; in:
;	r8 - pointer to kernel environment variables/routines
kernel_init_ipc:
	; preserve original registers
	push	rcx
	push	rdi

	; prepare the space for the stream space
	mov	rcx,	KERNEL_IPC_limit * LIB_SYS_STRUCTURE_IPC.SIZE
	add	rcx,	~STATIC_PAGE_mask
	shr	rcx,	STATIC_PAGE_SIZE_shift
	call	kernel_memory_alloc

	; preserve pointer to IPC messages
	mov	qword [r8 + KERNEL.ipc_base_address],	rdi

	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret