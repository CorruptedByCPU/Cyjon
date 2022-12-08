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
	push	r13

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
	jc	.error_memory	; no enough memory

	; load file content into prepared space
	mov	rsi,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id]
	call	kernel_storage_read

	; check if file have proper ELF header
	call	lib_elf_check
	jc	.error_elf	; it's not an ELF file

	; file has executable format?
	cmp	byte [rdi + LIB_ELF_STRUCTURE.type],	LIB_ELF_TYPE_executable
	jne	.error_elf	; no executable

	; preserve file location
	mov	r13,	rdi

	;-----------------------------------------------------------------------
	; prepare task for execution
	;-----------------------------------------------------------------------

	; register new task on queue
	mov	rcx,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + 0x20]
	mov	rsi,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + 0x18]
	call	kernel_task_add
	jc	.error_memory	; cannot register new task

	;-----------------------------------------------------------------------
	; paging array of new process
	;-----------------------------------------------------------------------

	; make space for the process paging table
	call	kernel_memory_alloc_page
	jc	.error_task	; no enough memory, remove task from queue

	; update task entry about paging array
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.cr3],	rdi

	;-----------------------------------------------------------------------
	; context stack and return point (initialization entry)
	;-----------------------------------------------------------------------

	; describe the space under context stack of process
	mov	rax,	KERNEL_TASK_STACK_address
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_process
	mov	ecx,	KERNEL_TASK_STACK_SIZE_page
	mov	r11,	rdi
	call	kernel_page_alloc
	jc	.error_page	; no enough memory, release paging array and remove task from queue

	; set process context stack pointer
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.rsp],	KERNEL_TASK_STACK_pointer - KERNEL_EXEC_STRUCTURE_RETURN.SIZE

	; prepare exception exit mode on context stack of process
	mov	rax,	KERNEL_TASK_STACK_pointer - STATIC_PAGE_SIZE_byte
	call	kernel_page_address

	; move pointer to return descriptor
	add	rdx,	STATIC_PAGE_SIZE_byte - KERNEL_EXEC_STRUCTURE_RETURN.SIZE

	; set first instruction executed by process
	mov	rax,	qword [r13 + LIB_ELF_STRUCTURE.program_entry_position]
	mov	qword [rdx + KERNEL_EXEC_STRUCTURE_RETURN.rip],	rax

	; code descriptor
	mov	qword [rdx + KERNEL_EXEC_STRUCTURE_RETURN.cs],	KERNEL_GDT_STRUCTURE.cs_ring3 | 0x03

	; default processor state flags
	mov	qword [rdx + KERNEL_EXEC_STRUCTURE_RETURN.eflags],	KERNEL_TASK_EFLAGS_default

	; default stack pointer
	mov	qword [rdx + KERNEL_EXEC_STRUCTURE_RETURN.rsp],	KERNEL_EXEC_STACK_pointer

	; stack descriptor
	mov	qword [rdx + KERNEL_EXEC_STRUCTURE_RETURN.ss],	KERNEL_GDT_STRUCTURE.ds_ring3 | 0x03

	;-----------------------------------------------------------------------
	; stack
	;-----------------------------------------------------------------------

	; describe the space under context stack of process
	mov	rax,	KERNEL_EXEC_STACK_address
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_process
	mov	ecx,	STATIC_PAGE_SIZE_page
	call	kernel_page_alloc
	jc	.error_page	; no enough memory, release paging array and remove task from queue

.end:
	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; restore original registers
	pop	r13
	pop	r8
	pop	rbp
	pop	rsi
	pop	rcx
	pop	rax

	; return from routine
	ret

.error_page:

.error_task:
	; release task entry
	mov	word [r10 + KERNEL_TASK_STRUCTURE.flags],	EMPTY

.error_memory:
	; return error code
	or	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_STRUCTURE.task_and_status],	SYS_ERROR_memory_no_enough

	; end of function
	jmp	.end

.error_elf:
	; return error code
	or	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_STRUCTURE.task_and_status],	SYS_ERROR_exec_not_executable

	; end of function
	jmp	.end

.error_file:
	; return error code
	or	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_STRUCTURE.task_and_status],	SYS_ERROR_file_not_found

	; end of function
	jmp	.end