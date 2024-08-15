;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_cmd:
	; kernel file available?
	cmp	qword [kernel_limine_kernel_file_request + LIMINE_KERNEL_FILE_REQUEST.response],	EMPTY
	je	.error	; no

	; properties of cmd line
	mov	rsi,	qword [kernel_limine_kernel_file_request + LIMINE_KERNEL_FILE_REQUEST.response]
	mov	rsi,	qword [rsi + LIMINE_KERNEL_FILE_RESPONSE.kernel_file]
	mov	rsi,	qword [rsi + LIMINE_FILE.cmd]

	; retrieve executable name
	mov	rdi,	kernel_exec_file_init
	call	lib_string_length
	mov	byte [kernel_exec_file_init_length],	cl
	rep	movsb

	; return from subroutine
	ret

.error:
	; storage is not available
	mov	ecx,	kernel_log_storage_end - kernel_log_storage
	mov	rsi,	kernel_log_storage
	call	driver_serial_string

	; hold the door
	jmp	$