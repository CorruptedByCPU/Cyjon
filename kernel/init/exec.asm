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

	; ; execute init file
	movzx	ecx,	byte [kernel_exec_file_init_length]
	mov	rsi,	kernel_exec_file_init
	mov	edi,	LIB_SYS_STREAM_FLOW_out_to_parent_out
	call	kernel_exec

	; remove exec descriptor
	add	rsp,	KERNEL_EXEC_STRUCTURE.SIZE

	; restore original registers
	pop	rbp
	pop	rsi
	pop	rcx

	; return from routine
	ret