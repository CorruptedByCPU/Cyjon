;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_daemon:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; by default there is no PID for new process
	xor	eax,	eax

	;-----------------------------------------------------------------------
	; locate and load file into memory
	;-----------------------------------------------------------------------

	; daemon "Garbage Collector"
	mov	ecx,	kernel_daemon_file_gc_end - kernel_daemon_file_gc
	mov	rsi,	kernel_daemon_file_gc

	; file descriptor
	sub	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE
	mov	rbp,	rsp	; pointer of file descriptor
	call	kernel_exec_load

	; file loaded?
	cmp	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY
	je	.end	; no

	; set pointer to file content
	mov	r13,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.address]

	;-----------------------------------------------------------------------
	; prepare task for execution
	;-----------------------------------------------------------------------

	; register new task on queue
	call	kernel_task_add

	;-----------------------------------------------------------------------
	; paging array of new process
	;-----------------------------------------------------------------------

	; make space for the process paging table
	call	kernel_memory_alloc_page

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

	; process memory usage
	add	qword [r10 + KERNEL_TASK_STRUCTURE.page],	rcx

	; set process context stack pointer
	mov	rsi,	KERNEL_TASK_STACK_pointer - (KERNEL_EXEC_STRUCTURE_RETURN.SIZE + KERNEL_EXEC_STACK_OFFSET_registers)
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.rsp],	rsi

	; prepare exception exit mode on context stack of process
	mov	rsi,	KERNEL_TASK_STACK_pointer - STATIC_PAGE_SIZE_byte
	call	kernel_page_address

	; set pointer to return descriptor
	and	rax,	STATIC_PAGE_mask	; drop flags
	add	rax,	qword [kernel_page_mirror]	; convert to logical address
	add	rax,	STATIC_PAGE_SIZE_byte - KERNEL_EXEC_STRUCTURE_RETURN.SIZE

	; set first instruction executed by process
	mov	rdx,	qword [r13 + LIB_ELF_STRUCTURE.program_entry_position]
	add	rdx,	r13
	mov	qword [rax + KERNEL_EXEC_STRUCTURE_RETURN.rip],	rdx

	; code descriptor
	mov	qword [rax + KERNEL_EXEC_STRUCTURE_RETURN.cs],	KERNEL_GDT_STRUCTURE.cs_ring0

	; default processor state flags
	mov	qword [rax + KERNEL_EXEC_STRUCTURE_RETURN.eflags],	KERNEL_TASK_EFLAGS_default

	; default stack pointer
	mov	rdx,	KERNEL_TASK_STACK_pointer
	mov	qword [rax + KERNEL_EXEC_STRUCTURE_RETURN.rsp],	rdx

	; stack descriptor
	mov	qword [rax + KERNEL_EXEC_STRUCTURE_RETURN.ss],	KERNEL_GDT_STRUCTURE.ds_ring0

	;-----------------------------------------------------------------------
	; allocate space for executable segments
	;-----------------------------------------------------------------------

	; size of unpacked executable
	call	kernel_exec_size

	; assign memory space for executable
	add	rcx,	~STATIC_PAGE_mask
	shr	rcx,	STATIC_PAGE_SIZE_shift
	call	kernel_memory_alloc

	; process memory usage
	add	qword [r10 + KERNEL_TASK_STRUCTURE.page],	rcx

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

	; preserve original registers
	push	rcx
	push	rdi

	; segment destination
	add	rdi,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.virtual_address]

	; segment source
	mov	rsi,	r13
	add	rsi,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.segment_offset]

	; copy segment in place
	mov	rcx,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.segment_size]
	rep	movsb

	; restore original registers
	pop	rdi
	pop	rcx

.elf_header_next:
	; move pointer to next entry
	add	rdx,	LIB_ELF_STRUCTURE_HEADER.SIZE

	; end of hedaer table?
	dec	rcx
	jnz	.elf_header	; no

	;-----------------------------------------------------------------------
	; kernel environment
	;-----------------------------------------------------------------------

	; map kernel space to process
	mov	r15,	qword [kernel_environment_base_address]
	mov	r15,	qword [r15 + KERNEL.page_base_address]
	call	kernel_page_merge

	;-----------------------------------------------------------------------
	; standard input/output (stream)
	;-----------------------------------------------------------------------

	; set default input stream
	call	kernel_stream
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.stream_in],	rsi

	; process memory usage
	inc	qword [r10 + KERNEL_TASK_STRUCTURE.page]

	; properties of parent task
	call	kernel_task_active

	; set default output stream
	mov	rsi,	qword [r9 + KERNEL_TASK_STRUCTURE.stream_out]
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.stream_out],	rsi

	; increase stream usage
	inc	qword [rsi + KERNEL_STREAM_STRUCTURE.count]

	;-----------------------------------------------------------------------
	; new process initialized
	;-----------------------------------------------------------------------

	; mark task as ready
	or	word [r10 + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active | KERNEL_TASK_FLAG_daemon | KERNEL_TASK_FLAG_init

.end:
	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; restore original registers
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret