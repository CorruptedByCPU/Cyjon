;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	rcx - length of string in characters
;	rsi - pointer to string
kernel_exec:
	; preserve original registers
	push	rcx
	push	rsi
	push	rbp
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	;-----------------------------------------------------------------------
	; locate and load file into memory
	;-----------------------------------------------------------------------

	; file descriptor
	sub	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE
	mov	rbp,	rsp	; pointer of file descriptor

	; get file properties
	movzx	eax,	byte [r8 + KERNEL_STRUCTURE.storage_root_id]
	call	kernel_storage_file

	; file found?
	cmp	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY
	je	.error	; no

	nop

.error:
	; remote file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; restore original registers
	pop	r8
	pop	rbp
	pop	rsi
	pop	rcx

	; return from routine
	ret