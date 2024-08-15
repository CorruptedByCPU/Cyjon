;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_ipc:
	; preserve original registers
	push	rcx
	push	rdi

	; prepare the space for the stream space
	mov	rcx,	KERNEL_IPC_limit * LIB_SYS_STRUCTURE_IPC.SIZE
	add	rcx,	~STD_PAGE_mask
	shr	rcx,	STD_SHIFT_PAGE
	call	kernel_memory_alloc

	; preserve pointer to IPC messages
	mov	qword [r8 + KERNEL.ipc_base_address],	rdi

	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret