;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; in:
;	rcx - length of string in characters
;	rsi - pointer to string
;	rdi - stream flags
;	rbp - pointer to exec descriptor
; out:
;	rax - new process ID
kernel_exec:
	; preserve original registers
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
	push	r13
	push	r14

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel]

	; select file name from string
	call	lib_string_word

	; by default there is no PID for new process
	xor	eax,	eax

	;-----------------------------------------------------------------------
	; locate and load file into memory
	;-----------------------------------------------------------------------

	; file descriptor
	mov	rcx,	rbx
	sub	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE
	mov	rbp,	rsp	; pointer of file descriptor
	call	kernel_exec_load
	jc	.end	; something wrong with file

	; file loaded?
	cmp	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY
	je	.end	; no

	; load library dependencies
	mov	r13,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.address]
	call	kernel_library

	;-----------------------------------------------------------------------
	; configure executable
	;-----------------------------------------------------------------------

	; orignal name/path length
	mov	rcx,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + 0x50]
	call	kernel_exec_configure

	;-----------------------------------------------------------------------
	; connect libraries to file executable (if needed)
	;-----------------------------------------------------------------------
	call	kernel_exec_link

	;-----------------------------------------------------------------------
	; standard input/output (stream)
	;-----------------------------------------------------------------------

	; retrieve stream flow
	mov	rax,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE + 0x38]

	; prepare default input stream
	call	kernel_stream
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.stream_in],	rsi

	; connect output with input?
	test	rax,	LIB_SYS_STREAM_FLOW_out_to_in
	jnz	.stream_set	; yes

.no_loop:
	; properties of parent task
	call	kernel_task_active

	; connect output to parents input?
	test	rax,	LIB_SYS_STREAM_FLOW_out_to_parent_in
	jz	.no_input	; no

	; redirect output to parents input
	mov	rsi,	qword [r9 + KERNEL_TASK_STRUCTURE.stream_in]

	; stream configured
	jmp	.stream_set

.no_input:
	; default configuration
	mov	rsi,	qword [r9 + KERNEL_TASK_STRUCTURE.stream_out]

.stream_set:
	; update stream output of child
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.stream_out],	rsi

	; increase stream usage
	inc	qword [rsi + KERNEL_STREAM_STRUCTURE.count]

	;-----------------------------------------------------------------------
	; new process initialized
	;-----------------------------------------------------------------------

	; mark task as ready
	or	word [r10 + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active | KERNEL_TASK_FLAG_init

	; release file content
	mov	rsi,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.size_byte]
	add	rsi,	~STD_PAGE_mask
	shr	rsi,	STD_PAGE_SIZE_shift
	mov	rdi,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.address]
	call	kernel_memory_release

	; return task ID
	mov	rax,	qword [r10 + KERNEL_TASK_STRUCTURE.pid]

.end:
	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; restore original registers
	pop	r14
	pop	r13
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

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - length of path
;	rsi - pointer to path
;	r13 - pointer to file content
; out:
;	rdi - pointer to executable space
;	r10 - pointer to task entry
kernel_exec_configure:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rbp
	push	r8
	push	r9
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

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
	mov	rax,	KERNEL_STACK_address
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_process
	mov	ecx,	KERNEL_STACK_page
	mov	r11,	rdi
	call	kernel_page_alloc

	; set process context stack pointer
	mov	rsi,	KERNEL_STACK_pointer - (KERNEL_EXEC_STRUCTURE_RETURN.SIZE + KERNEL_EXEC_STACK_OFFSET_registers)
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.rsp],	rsi

	; prepare exception exit mode on context stack of process
	mov	rsi,	KERNEL_STACK_pointer - STD_PAGE_SIZE_byte
	call	kernel_page_address

	; set pointer to return descriptor
	and	rax,	STD_PAGE_mask	; drop flags
	add	rax,	qword [kernel_page_mirror]	; convert to logical address
	add	rax,	STD_PAGE_SIZE_byte - KERNEL_EXEC_STRUCTURE_RETURN.SIZE

	; set first instruction executed by process
	mov	rdx,	qword [r13 + LIB_ELF_STRUCTURE.program_entry_position]
	mov	qword [rax + KERNEL_EXEC_STRUCTURE_RETURN.rip],	rdx

	; code descriptor
	mov	qword [rax + KERNEL_EXEC_STRUCTURE_RETURN.cs],	KERNEL_STRUCTURE_GDT.cs_ring3 | 0x03

	; default processor state flags
	mov	qword [rax + KERNEL_EXEC_STRUCTURE_RETURN.eflags],	KERNEL_TASK_EFLAGS_default

	; default stack pointer
	mov	rdx,	KERNEL_EXEC_STACK_pointer
	mov	qword [rax + KERNEL_EXEC_STRUCTURE_RETURN.rsp],	rdx

	; stack descriptor
	mov	qword [rax + KERNEL_EXEC_STRUCTURE_RETURN.ss],	KERNEL_STRUCTURE_GDT.ss_ring3 | 0x03

	;-----------------------------------------------------------------------
	; stack
	;-----------------------------------------------------------------------

	; length of string passed to process
	mov	rcx,	qword [rsp + 0x50]
	xor	cl,	cl
	add	rcx,	0x18

	; remember as offset inside process stack
	mov	rdx,	rcx
	not	dx
	and	dx,	~STD_PAGE_mask
	inc	dx

	; new stack pointer of process
	sub	qword [rax + KERNEL_EXEC_STRUCTURE_RETURN.rsp], rcx

	; stack base address
	mov	rax,	KERNEL_EXEC_STACK_pointer
	add	rcx,	~STD_PAGE_mask
	and	rcx,	STD_PAGE_mask
	sub	rax,	rcx

	; alloc stack of size with arguments
	shr	rcx,	STD_PAGE_SIZE_shift
	call	kernel_memory_alloc

	; preserve length and pointer to stack
	push	rcx
	push	rdi

	; arguments line position on stack
	add	di,	dx	; offset

	; share to process:

	; length of arguments in Bytes
	mov	rcx,	qword [rsp + 0x60]
	mov	qword [rdi],	rcx	; length of string

	; string of arguments
	mov	rsi,	qword [rsp + 0x50]
	add	rdi,	0x08
	rep	movsb

	; restore length and pointer to stack
	pop	rdi
	pop	rcx

	; map executable space to process paging array
	or	bx,	KERNEL_PAGE_FLAG_user
	mov	rsi,	rdi
	sub	rsi,	qword [kernel_page_mirror]
	call	kernel_page_map

	; process memory usage
	add	qword [r10 + KERNEL_TASK_STRUCTURE.page],	rcx

	; process stack size
	add	qword [r10 + KERNEL_TASK_STRUCTURE.stack],	rcx

	;-----------------------------------------------------------------------
	; allocate space for executable segments
	;-----------------------------------------------------------------------

	; size of unpacked executable
	call	kernel_exec_size

	; convert limit address to offset
	sub	rcx,	KERNEL_EXEC_BASE_address

	; assign memory space for executable
	add	rcx,	~STD_PAGE_mask
	shr	rcx,	STD_PAGE_SIZE_shift
	call	kernel_memory_alloc

	; preserve executable location and size in Pages
	push	rdi
	push	rcx

	; map executable space to process paging array
	mov	eax,	KERNEL_EXEC_BASE_address
	mov	rsi,	rdi
	sub	rsi,	qword [kernel_page_mirror]
	call	kernel_page_map

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
	sub	rdi,	KERNEL_EXEC_BASE_address

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
	; virtual memory map
	;-----------------------------------------------------------------------

	; assign memory space for binary memory map with same size as kernels
	mov	rcx,	qword [r8 + KERNEL.page_limit]
	shr	rcx,	STD_DIVIDE_BY_8_shift	; 8 pages per Byte
	add	rcx,	~STD_PAGE_mask	; align up to page boundaries
	shr	rcx,	STD_PAGE_SIZE_shift	; convert to pages
	call	kernel_memory_alloc

	; store binary memory map address of process inside task properties
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.memory_map],	rdi

	; preserve binary memory map location
	push	rdi

	; fill memory map with available pages
	mov	eax,	STD_MAX_unsigned
	mov	rcx,	qword [r8 + KERNEL.page_limit]
	shr	rcx,	STD_DIVIDE_BY_32_shift	; 32 pages per chunk

	; first 1 MiB is reserved for future devices mapping
	sub	rcx,	(KERNEL_EXEC_BASE_address >> STD_PAGE_SIZE_shift) >> STD_DIVIDE_BY_32_shift
	add	rdi,	(KERNEL_EXEC_BASE_address >> STD_PAGE_SIZE_shift) >> STD_DIVIDE_BY_8_shift

	; proceed
	rep	stosd

	; restore memory map location and executable space size in Pages
	pop	rsi
	pop	rcx

	; mark first N bytes of executable space as reserved
	mov	r9,	rsi
	call	kernel_memory_acquire

	;-----------------------------------------------------------------------
	; kernel environment
	;-----------------------------------------------------------------------

	; map kernel space to process
	mov	r15,	qword [kernel]
	mov	r15,	qword [r15 + KERNEL.page_base_address]
	call	kernel_page_merge

	; restore executable space address
	pop	rdi

	; restore original registers
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r9
	pop	r8
	pop	rbp
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to logical executable space
;	r13 - pointer to file content
kernel_exec_link:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13

	; we need to find 4 header locations to be able to resolve bindings to functions

	;----------------------------------------------------------------------
	; search for RELA section of file
	mov	eax,	LIB_ELF_SECTION_TYPE_rela
	call	kernel_library_section_by_type
	jc	.end	; file doesn't require external libraries

	; set pointer to RELA
	mov	r8,	qword [rax + LIB_ELF_STRUCTURE_SECTION.file_offset]
	add	r8,	r13

	; and size on Bytes
	mov	rbx,	qword [rax + LIB_ELF_STRUCTURE_SECTION.size_byte]

	;----------------------------------------------------------------------
	; search for DYNAMIC SYMBOLS section of file
	mov	eax,	LIB_ELF_SECTION_TYPE_dynsym
	call	kernel_library_section_by_type

	; set pointer to DYNAMIC SYMBOLS
	mov	r9,	qword [rax + LIB_ELF_STRUCTURE_SECTION.file_offset]
	add	r9,	r13

	;----------------------------------------------------------------------
	; search for STRTAB section of file
	mov	eax,	LIB_ELF_SECTION_TYPE_strtab
	call	kernel_library_section_by_type

	; set pointer to STRTAB
	mov	r10,	qword [rax + LIB_ELF_STRUCTURE_SECTION.file_offset]
	add	r10,	r13

	;----------------------------------------------------------------------
	; search for GOT.PLT section of file
	mov	rsi,	kernel_library_string_got_plt
	call	kernel_library_section_by_name


	; change memory location to process
	mov	r11,	qword [rax + LIB_ELF_STRUCTURE_SECTION.file_offset]
	add	r11,	rdi

	; set pointer to first function address entry
	add	r11,	0x18

	;----------------------------------------------------------------------
	; function index inside Global Offset Table
	xor	r12,	r12

.function:
	; or symbolic value exist
	cmp	qword [r8 + LIB_ELF_STRUCTURE_DYNAMIC_RELOCATION.symbol_value],	EMPTY
	jne	.function_next

	; get function index
	mov	eax,	dword [r8 + LIB_ELF_STRUCTURE_DYNAMIC_RELOCATION.index]

	; calculate offset to function name
	mov	rcx,	LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.SIZE
	mul	rcx

	; set pointer to function name
	mov	esi,	dword [r9 + rax]
	add	rsi,	r10

	; calculate function name length
	call	lib_string_length

	; retrieve function address
	call	kernel_library_function

	; insert function address to GOT at RCX offset
	mov	qword [r11 + r12 * 0x08],	rax

.function_next:
	; move pointer to next entry
	add	r8,	LIB_ELF_STRUCTURE_DYNAMIC_RELOCATION.SIZE

	; next function index
	inc	r12

	; no more entries?
	sub	rbx,	LIB_ELF_STRUCTURE_DYNAMIC_RELOCATION.SIZE
	jnz	.function	; no

.end:
	; restore original registers
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - length of path
;	rsi - pointer to path
;	rbp - pointer to file descriptor
; out:
;	CF - if file not exist
kernel_exec_load:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel]

	; get file properties
	movzx	eax,	byte [r8 + KERNEL.storage_root_id]
	call	kernel_storage_file

	; file exist?
	cmp	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY
	je	.end	; no

	; prepare space for file content
	mov	rcx,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.size_byte]
	add	rcx,	~STD_PAGE_mask
	shr	rcx,	STD_PAGE_SIZE_shift
	call	kernel_memory_alloc

	; load file content into prepared space
	mov	rsi,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id]
	call	kernel_storage_read

	; proper ELF file?
	call	lib_elf_check
	jc	.error	; no

	; it's an executable file?
	cmp	word [rdi + LIB_ELF_STRUCTURE.type],	LIB_ELF_TYPE_executable
	je	.ok	; yes

.error:
	; release assigned memory
	mov	rsi,	rcx
	call	kernel_memory_release

	; set error flag
	stc

	; end of routine
	jmp	.end

.ok:
	; return file content address
	mov	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.address],	rdi

.end:
	; restore original registers
	pop	r8
	pop	rsi
	pop	rcx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	r13 - pointer to file content
; out:
;	rcx - farthest segment limit in Bytes
kernel_exec_size:
	; preserve original registers
	push	rbx
	push	rdx

	; number of header entries
	movzx	ebx,	word [r13 + LIB_ELF_STRUCTURE.header_entry_count]

	; length of memory space in Bytes
	xor	ecx,	ecx

	; beginning of header table
	mov	rdx,	qword [r13 + LIB_ELF_STRUCTURE.header_table_position]
	add	rdx,	r13

.calculate:
	; ignore empty entries
	cmp	dword [rdx + LIB_ELF_STRUCTURE_HEADER.type],	EMPTY
	je	.leave	; empty one
	cmp	qword [rdx + LIB_ELF_STRUCTURE_HEADER.memory_size],	EMPTY
	je	.leave	; this too

	; segment required in memory?
	cmp	dword [rdx + LIB_ELF_STRUCTURE_HEADER.type],	LIB_ELF_HEADER_TYPE_load
	jne	.leave	; no

	; this segment is after previous one?
	cmp	rcx,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.virtual_address]
	ja	.leave	; no

	; remember end of segment address
	mov	rcx,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.virtual_address]
	add	rcx,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.segment_size]

.leave:
	; move pointer to next entry
	add	rdx,	LIB_ELF_STRUCTURE_HEADER.SIZE

	; end of table?
	dec	ebx
	jnz	.calculate	; no

	; restore original registers
	pop	rdx
	pop	rbx

	; return from routine
	ret