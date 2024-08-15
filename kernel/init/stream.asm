;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_stream:
	; preserve original registers
	push	rcx
	push	rsi
	push	rdi
	push	r9

	; assign space for stream cache
	mov	ecx,	((KERNEL_STREAM_limit * KERNEL_STREAM_STRUCTURE.SIZE) + ~STD_PAGE_mask) >> STD_PAGE_SIZE_shift
	call	kernel_memory_alloc

	; save it
	mov	qword [r8 + KERNEL.stream_base_address],	rdi

	; prepare streams for kernel process
	call	kernel_stream

	; as a kernel, both streams are of type null
	or	byte [rsi + KERNEL_STREAM_STRUCTURE.flags],	LIB_SYS_STREAM_FLAG_null

	; insert streams into kernel task
	call	kernel_task_active
	mov	qword [r9 + KERNEL_TASK_STRUCTURE.stream_in],	rsi
	mov	qword [r9 + KERNEL_TASK_STRUCTURE.stream_out],	rsi

	; share stream functions with daemons
	mov	qword [r8 + KERNEL.stream_release],	kernel_stream_release

	; restore original registers
	pop	r9
	pop	rdi
	pop	rsi
	pop	rcx

	; return from routine
	ret