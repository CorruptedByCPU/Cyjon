;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_cmd:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi

	; kernel file properties
	mov	rsi,	qword [limine_kernel_file_request + LIMINE_KERNEL_FILE_REQUEST.response]
	mov	rsi,	qword [rsi + LIMINE_KERNEL_FILE_RESPONSE.kernel_file]

	; select pointer to CMDLINE field
	mov	rsi,	qword [rsi + LIMINE_FILE.cmdline]

	; execute software passed by CMDLINE field
	xor	eax,	eax	; default stream flow
	call	lib_string_length
	call	kernel_exec

	; restore original register
	pop	rsi
	pop	rcx
	pop	rax

	; return from routine
	ret