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
	push	rbx
	push	rdx
	push	rdi
	push	rbp
	push	r8
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
	push	rsi
	push	rcx

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; by default there is no PID for new process
	mov	qword [rbp + KERNEL_EXEC_STRUCTURE.pid],	EMPTY

	;-----------------------------------------------------------------------
	; locate and load file into memory
	;-----------------------------------------------------------------------

	; file descriptor
	sub	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE
	mov	rbp,	rsp	; pointer of file descriptor

	; get file properties
	movzx	eax,	byte [r8 + KERNEL_STRUCTURE.storage_root_id]
	call	kernel_storage_file

	; prepare error code
	mov	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_DESCRIPTOR_offset + KERNEL_EXEC_STRUCTURE.task_or_status],	LIB_SYS_ERROR_file_not_found

	; file found?
	cmp	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY
	je	.end	; no

	; prepare error code
	mov	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_DESCRIPTOR_offset + KERNEL_EXEC_STRUCTURE.task_or_status],	LIB_SYS_ERROR_memory_no_enough

	; prepare space for file content
	mov	rcx,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.size_byte]
	add	rcx,	~STATIC_PAGE_mask
	shr	rcx,	STATIC_PAGE_SIZE_shift
	call	kernel_memory_alloc
	jc	.end	; no enough memory

	; load file content into prepared space
	mov	rsi,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id]
	call	kernel_storage_read

	; preserve file size in pages and location
	mov	r12,	rcx
	mov	r13,	rdi

	; prepare error code
	mov	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_DESCRIPTOR_offset + KERNEL_EXEC_STRUCTURE.task_or_status],	LIB_SYS_ERROR_exec_not_executable

	; check if file have proper ELF header
	call	lib_elf_check
	jc	.error_level_file	; it's not an ELF file

	; file has executable format?
	cmp	byte [rdi + LIB_ELF_STRUCTURE.type],	LIB_ELF_TYPE_executable
	jne	.error_level_file	; no executable

	;-----------------------------------------------------------------------
	; prepare task for execution
	;-----------------------------------------------------------------------

	; register new task on queue
	mov	rcx,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE]
	mov	rsi,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + STATIC_PTR_SIZE_byte]
	call	kernel_task_add
	jc	.error_level_file	; cannot register new task

	;-----------------------------------------------------------------------
	; paging array of new process
	;-----------------------------------------------------------------------

	; prepare error code
	mov	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_DESCRIPTOR_offset + KERNEL_EXEC_STRUCTURE.task_or_status],	LIB_SYS_ERROR_exec_not_executable

	; make space for the process paging table
	call	kernel_memory_alloc_page
	jc	.error_level_task	; no enough memory

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
	jc	.error_level_page	; no enough memory

	; set process context stack pointer
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.rsp],	KERNEL_TASK_STACK_pointer - (KERNEL_EXEC_STRUCTURE_RETURN.SIZE + KERNEL_EXEC_STACK_OFFSET_registers)

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
	mov	rax,	KERNEL_EXEC_STACK_pointer
	mov	qword [rdx + KERNEL_EXEC_STRUCTURE_RETURN.rsp],	rax

	; stack descriptor
	mov	qword [rdx + KERNEL_EXEC_STRUCTURE_RETURN.ss],	KERNEL_GDT_STRUCTURE.ds_ring3 | 0x03

	;-----------------------------------------------------------------------
	; stack
	;-----------------------------------------------------------------------

	; describe the space under context stack of process
	mov	rax,	KERNEL_EXEC_STACK_address
	or	bx,	KERNEL_PAGE_FLAG_user
	mov	ecx,	STATIC_PAGE_SIZE_page
	call	kernel_page_alloc
	jc	.error_level_page	; no enough memory

	;-----------------------------------------------------------------------
	; load program segments in place
	;-----------------------------------------------------------------------

	; number of program headers
	movzx	ecx,	word [r13 + LIB_ELF_STRUCTURE.header_entry_count]

	; beginning of header section
	mov	rdx,	qword [r13 + LIB_ELF_STRUCTURE.header_table_position]
	add	rdx,	r13

.elf_header:
	; ignore empty headers
	cmp	dword [rdx + LIB_ELF_STRUCTURE_HEADER.type],	EMPTY
	je	.elf_header_next	; empty one
	cmp	qword [rdx + LIB_ELF_STRUCTURE_HEADER.memory_size],	EMPTY
	je	.elf_header_next	; this too

	; load segment?
	cmp	dword [rdx + LIB_ELF_STRUCTURE_HEADER.type],	LIB_ELF_HEADER_TYPE_load
	jne	.elf_header_next	; no

	; calculate segment address
	mov	r14,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.virtual_address]
	and	r14,	STATIC_PAGE_mask	; align down to page boundary

	; calculate segment size in pages
	mov	rax,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.virtual_address]
	and	rax,	STATIC_PAGE_mask	; preserve only page number
	mov	r15,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.virtual_address]
	add	r15,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.segment_size]
	sub	r15,	rax
	; align up to next page boundary
	add	r15,	STATIC_PAGE_SIZE_byte - 1
	shr	r15,	STATIC_PAGE_SIZE_shift

	; preserve original register
	push	rcx

	; assign memory space for segment
	mov	rcx,	r15
	call	kernel_memory_alloc

	; restore original register
	pop	rcx

	; if no enough memory
	jc	.error_level_page	; no enough memory

	; source
	mov	rsi,	r13
	add	rsi,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.segment_offset]

	; preserve segment pointer and original register
	push	rcx
	push	rdi

	; target
	and	qword [rdx + LIB_ELF_STRUCTURE_HEADER.virtual_address],	~STATIC_PAGE_mask
	add	rdi,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.virtual_address]

	; copy file segment in place
	mov	rcx,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.segment_size]
	rep	movsb

	; restore segment pointer
	pop	rsi

	; map segment to process paging array
	mov	rax,	r14
	mov	rcx,	r15
	sub	rsi,	qword [kernel_page_mirror]
	call	kernel_page_map

	; restore original register
	pop	rcx

	; if no enough memory
	jc	.error_level_page

.elf_header_next:
	; move pointer to next entry
	add	rdx,	LIB_ELF_STRUCTURE_HEADER.SIZE

	; end of hedaer table?
	dec	rcx
	jnz	.elf_header	; no

	;-----------------------------------------------------------------------
	; virtual memory map
	;-----------------------------------------------------------------------

	; assign memory space for for binary memory map with same size as kernel
	mov	rcx,	qword [r8 + KERNEL_STRUCTURE.page_limit]
	shr	rcx,	STATIC_DIVIDE_BY_8_shift	; 8 pages by Byte
	add	rcx,	~STATIC_PAGE_mask	; align up to page boundaries
	shr	rcx,	STATIC_PAGE_SIZE_shift	; convert to pages
	call	kernel_memory_alloc

	; preserve binary memory size and location
	push	rdi
	push	rcx

	; fill memory map with available pages
	mov	rax,	STATIC_MAX_unsigned
	shl	rcx,	STATIC_MULTIPLE_BY_512_shift
	rep	stosq

	; restore binary memory size
	pop	rcx

	; everything before binary memory map (and in itself) is not available for process
	; mark that space as unavailable

	; first available page number
	mov	rax,	r14	; last segment position
	shr	rax,	STATIC_PAGE_SIZE_shift
	add	rax,	rcx	; last segment size in pages

	; restore memory map location
	pop	rsi

.reserved:
	; mark page as reserved
	btr	qword [rsi],	rax

	; mark other pages?
	dec	rax
	jns	.reserved	; yes

	; map binary memory map to process paging array
	mov	rax,	r15
	shl	rax,	STATIC_PAGE_SIZE_shift
	add	rax,	r14
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_process
	shl	rsi,	17	; convert source address to physical
	shr	rsi,	17
	call	kernel_page_map

	; store binary memory map address inside task properties
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.memory_map],	rax

	;-----------------------------------------------------------------------
	; kernel environment
	;-----------------------------------------------------------------------

	; map kernel space to process
	call	kernel_page_merge

	;-----------------------------------------------------------------------
	; new process initialized
	;-----------------------------------------------------------------------

	; mark task as ready
	or	word [r10 + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active

	; return PID and pointer to task on queue
	push	qword [r10 + KERNEL_TASK_STRUCTURE.pid]
	pop	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_DESCRIPTOR_offset + KERNEL_EXEC_STRUCTURE.pid]
	mov	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + KERNEL_EXEC_DESCRIPTOR_offset + KERNEL_EXEC_STRUCTURE.task_or_status],	r10

.end:
	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; restore original registers
	pop	rcx
	pop	rsi
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r8
	pop	rbp
	pop	rdi
	pop	rdx
	pop	rbx
	pop	rax

	; return from routine
	ret

.error_level_page:
	; release paging structure and space
	call	kernel_page_deconstruction

.error_level_task:
	; release task entry
	mov	word [r10 + KERNEL_TASK_STRUCTURE.flags],	EMPTY

.error_level_file:
	; release space of loaded file
	mov	rcx,	r12
	mov	rdi,	r13
	call	kernel_memory_release

	; end of function
	jmp	.end