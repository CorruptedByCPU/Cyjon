;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
kernel_init_exec:
	; preserve original registers
	push	rcx
	push	rsi

	; execute init file
	mov	ecx,	KERNEL_EXEC_FILE_INIT_length
	mov	rsi,	kernel_exec_file_init
	call	kernel_exec

	; restore original registers
	pop	rsi
	pop	rcx

	; return from routine
	ret