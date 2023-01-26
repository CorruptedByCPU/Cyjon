;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
kernel_init_exec:
	; preserve original registers
	push	rcx
	push	rsi
	push	rbp

	; exec descriptor
	sub	rsp,	KERNEL_EXEC_STRUCTURE.SIZE
	mov	rbp,	rsp	; pointer of file descriptor

	; execute init file
	mov	ecx,	kernel_exec_file_init_end - kernel_exec_file_init
	mov	rsi,	kernel_exec_file_init
	mov	edi,	LIB_SYS_STREAM_FLOW_out_to_in
	call	kernel_exec

	; remove exec descriptor
	add	rsp,	KERNEL_EXEC_STRUCTURE.SIZE

	; restore original registers
	pop	rbp
	pop	rsi
	pop	rcx

	; return from routine
	ret