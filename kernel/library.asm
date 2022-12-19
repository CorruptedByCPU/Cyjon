;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; out:
;	r14 - pointer to new library entry
;	CF - set if no free entry
kernel_library_add:
	; preserve original registers
	push	rcx
	push	r14

	; search from first entry
	xor	ecx,	ecx

	; set pointer to begining of library entries
	mov	r14,	qword [kernel_environment_base_address]
	mov	r14,	qword [r14 + KERNEL_STRUCTURE.library_base_address]

.next:
	; entry is free?
	test	word [r14 + KERNEL_LIBRARY_STRUCTURE.flags],	KERNEL_LIBRARY_FLAG_active
	jz	.found	; yes

	; move pointer to next entry
	add	r14,	KERNEL_LIBRARY_STRUCTURE.SIZE

	; end of library structure?
	inc	rcx
	cmp	rcx,	KERNEL_LIBRARY_limit
	jb	.next	; no

	; free entry not found
	stc

	; end of routine
	jmp	.end

.found:
	; mark entry as active
	mov	word [r14 + KERNEL_LIBRARY_STRUCTURE.flags],	KERNEL_LIBRARY_FLAG_active

	; return entry pointer
	mov	qword [rsp],	r14

.end:
	; restore original registers
	pop	r14
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - length of name
;	rsi - pointer to string
; out:
;	r14 - library descriptor pointer or error
;	CF - set if there was error
kernel_library_load:
	; preserve original registers
	push	rax
	push	rbx
	push	rdx
	push	rdi
	push	rbp
	push	r8
	push	r12
	push	r13
	push	rsi
	push	rcx
	push	r14

	; prepare error code
	mov	qword [rsp],	LIB_SYS_ERROR_memory_no_enough

	; prepare new entry for library
	call	kernel_library_add
	jc	.end	; no enough memory

	;-----------------------------------------------------------------------
	; locate and load file into memory
	;-----------------------------------------------------------------------

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; file descriptor
	sub	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE
	mov	rbp,	rsp	; pointer of file descriptor

	; get file properties
	movzx	eax,	byte [r8 + KERNEL_STRUCTURE.storage_root_id]
	call	kernel_storage_file

	; prepare error code
	mov	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE],	LIB_SYS_ERROR_file_not_found

	; file found?
	cmp	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY
	je	.error_level_descriptor	; no

	; prepare error code
	mov	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE],	LIB_SYS_ERROR_memory_no_enough

	; prepare space for file content
	mov	rcx,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.size_byte]
	add	rcx,	~STATIC_PAGE_mask
	shr	rcx,	STATIC_PAGE_SIZE_shift
	call	kernel_memory_alloc
	jc	.error_level_descriptor	; no enough memory

	; load file content into prepared space
	mov	rsi,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id]
	call	kernel_storage_read

	; preserve file size in pages and location
	mov	r12,	rcx
	mov	r13,	rdi

	; prepare error code
	mov	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE],	LIB_SYS_ERROR_exec_not_executable

	; check if file have proper ELF header
	call	lib_elf_check
	jc	.error_level_file	; it's not an ELF file

	; check if it is a shared library
	cmp	byte [rdi + LIB_ELF_STRUCTURE.type],	LIB_ELF_TYPE_shared_object
	jne	.error_level_file	; no library

	;-----------------------------------------------------------------------
	; calculate library size in Pages
	;-----------------------------------------------------------------------

	; first of we should calculate much space unpacked library needs (in pages)

	; number of program headers
	movzx	ebx,	word [r13 + LIB_ELF_STRUCTURE.header_entry_count]

	; length of memory space in Bytes
	xor	ecx,	ecx

	; beginning of header section
	mov	rdx,	qword [r13 + LIB_ELF_STRUCTURE.header_table_position]
	add	rdx,	r13

.calculate:
	; ignore empty headers
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

	; end of hedaer table?
	dec	ebx
	jnz	.calculate	; no

	; by now we have address of fartest point in memory of library
	; convert this address to length in pages
	add	rcx,	~STATIC_PAGE_mask
	shr	rcx,	STATIC_PAGE_SIZE_shift

	; prepare error code
	mov	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE],	LIB_SYS_ERROR_memory_no_enough

	; assign memory space for all segments at once
	call	kernel_memory_alloc
	jc	.error_level_file	; no enough memory

	;-----------------------------------------------------------------------
	; load library segments in place
	;-----------------------------------------------------------------------

	; number of program headers
	movzx	ebx,	word [r13 + LIB_ELF_STRUCTURE.header_entry_count]

	; beginning of header section
	mov	rdx,	qword [r13 + LIB_ELF_STRUCTURE.header_table_position]
	add	rdx,	r13

.segment:
	; ignore empty headers
	cmp	dword [rdx + LIB_ELF_STRUCTURE_HEADER.type],	EMPTY
	je	.next	; empty one
	cmp	qword [rdx + LIB_ELF_STRUCTURE_HEADER.memory_size],	EMPTY
	je	.next	; this too

	; segment required in memory?
	cmp	dword [rdx + LIB_ELF_STRUCTURE_HEADER.type],	LIB_ELF_HEADER_TYPE_load
	jne	.next	; no

	; segment source
	mov	rsi,	r13
	add	rsi,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.segment_offset]

	; preserve original library location
	push	rdi

	; segment target
	add	rdi,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.virtual_address]

	; copy library segment in place
	mov	rcx,	qword [rdx + LIB_ELF_STRUCTURE_HEADER.segment_size]
	rep	movsb

	; restore original library location
	pop	rdi

.next:
	; move pointer to next entry
	add	rdx,	LIB_ELF_STRUCTURE_HEADER.SIZE

	; end of header table?
	dec	ebx
	jnz	.segment	; no

	;-----------------------------------------------------------------------
	; library available, update entry
	;-----------------------------------------------------------------------

	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; release space of loaded file
	mov	rcx,	r12
	mov	rdi,	r13
	call	kernel_memory_release

	; preserve library content pointer and size in pages
	mov	qword [r14 + KERNEL_LIBRARY_STRUCTURE.address],	r13
	mov	word [r14 + KERNEL_LIBRARY_STRUCTURE.size_page],	r12w

	; register library name and length

	; length in characters
	mov	rcx,	qword [rsp + STATIC_QWORD_SIZE_byte]
	mov	byte [r14 + KERNEL_LIBRARY_STRUCTURE.length],	cl

	; name
	mov	rsi,	qword [rsp + (STATIC_QWORD_SIZE_byte << STATIC_MULTIPLE_BY_2_shift)]
	lea	rdi,	[r14 + KERNEL_LIBRARY_STRUCTURE.name]
	rep	movsb

	; return pointer to library entry
	mov	qword [rsp],	r14

.end:
	; restore original registers
	pop	r14
	pop	rcx
	pop	rsi
	pop	r13
	pop	r12
	pop	r8
	pop	rbp
	pop	rdi
	pop	rdx
	pop	rbx
	pop	rax

	; return from routine
	ret

.error_level_file:
	; release space of loaded file
	mov	rcx,	r12
	mov	rdi,	r13
	call	kernel_memory_release

.error_level_descriptor:
	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE	

.error_level_default:
	; free up library entry
	mov	word [r14 + KERNEL_LIBRARY_STRUCTURE.flags],	EMPTY

	; set error flag
	stc

	; end of routine
	jmp	.end