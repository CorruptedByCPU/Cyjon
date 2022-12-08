;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	rcx - length of string in characters
;	rsi - pointer to string
;	rbp - pointer to exec descriptor
kernel_exec:
	; preserve original registers
	push	rax
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
	je	.error_file	; no

	; prepare space for file content
	mov	rcx,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.size_byte]
	add	rcx,	~STATIC_PAGE_mask
	shr	rcx,	STATIC_PAGE_SIZE_shift
	call	kernel_memory_alloc

	; no enough memory?
	test	rdi,	rdi
	jz	.error_memory

	; load file content into prepared space
	mov	rsi,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id]
	call	kernel_storage_read

	; check if file have proper ELF header
	call	lib_elf_check
	jc	.error_elf	; it's not an ELF file

	; file has executable format?
	cmp	byte [rdi + LIB_ELF_STRUCTURE.type],	LIB_ELF_TYPE_executable
	jne	.error_elf	; no executable

	;-----------------------------------------------------------------------
	; prepare task for execution
	;-----------------------------------------------------------------------

	; register new task on queue
	mov	rcx,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + 0x18]
	mov	rsi,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + 0x10]
	call	kernel_task_add

	; cannot register new task?
	test	r10,	r10
	jz	.error_memory	; yes

	nop

.end:
	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; restore original registers
	pop	r8
	pop	rbp
	pop	rsi
	pop	rcx
	pop	rax

	; return from routine
	ret

.error_elf:
	; return error code
	or	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_STRUCTURE.task_and_status],	SYS_ERROR_exec_not_executable

	; end of function
	jmp	.end

.error_memory:
	; return error code
	or	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_STRUCTURE.task_and_status],	SYS_ERROR_memory_no_enough

	; end of function
	jmp	.end

.error_file:
	; return error code
	or	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_STRUCTURE.task_and_status],	SYS_ERROR_file_not_found

	; end of function
	jmp	.end