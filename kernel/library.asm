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
;	cl - length of name
;	rsi - pointer to string
; out:
;	r14 - library descriptor pointer
;	CF - set if doesn't exist
kernel_library_find:
	; preserve original registers
	push	rbx
	push	rdi
	push	r14

	; search from first entry
	xor	ebx,	ebx

	; set pointer to begining of library entries
	mov	r14,	qword [kernel_environment_base_address]
	mov	r14,	qword [r14 + KERNEL_STRUCTURE.library_base_address]

.find:
	; entry is empty?
	cmp	word [r14 + KERNEL_LIBRARY_STRUCTURE.flags],	EMPTY
	je	.next	; yes

	; length of entry name is the same?
	cmp	byte [r14 + KERNEL_LIBRARY_STRUCTURE.length],	cl
	jne	.next	; no

	; we found library?
	lea	rdi,	[r14 + KERNEL_LIBRARY_STRUCTURE.name]
	call	lib_string_compare
	jnc	.found	; yes

.next:
	; move pointer to next entry
	add	r14,	KERNEL_LIBRARY_STRUCTURE.SIZE

	; end of library structure?
	inc	ebx
	cmp	ebx,	KERNEL_LIBRARY_limit
	jb	.find	; no

	; free entry not found
	stc

	; end of routine
	jmp	.end

.found:
	; return entry pointer
	mov	qword [rsp],	r14

.end:
	; restore original registers
	pop	r14
	pop	rdi
	pop	rbx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	r13 - pointer file content
; out:
;	CF - set if cannot load library
kernel_library_import:
	; preserve original registers
	push	rcx
	push	rsi
	push	r14
	push	r13

	; number of entries in section header
	movzx	ecx,	word [r13 + LIB_ELF_STRUCTURE.section_entry_count]

	; set pointer to begining of section header
	add	r13,	qword [r13 + LIB_ELF_STRUCTURE.section_table_position]

.section:
	; string table?
	cmp	dword [r13 + LIB_ELF_STRUCTURE_SECTION.type],	LIB_ELF_SECTION_TYPE_string_table
	jne	.next	; no

	; preserve pointer to string table
	mov	rsi,	qword [rsp]
	add	rsi,	qword [r13 + LIB_ELF_STRUCTURE_SECTION.file_offset]

.next:
	; dynamic section?
	cmp	dword [r13 + LIB_ELF_STRUCTURE_SECTION.type],	LIB_ELF_SECTION_TYPE_dynamic
	je	.parse	; yes

	; move pointer to next entry
	add	r13,	LIB_ELF_STRUCTURE_SECTION.SIZE

	; end of library structure?
	loop	.section

	; end of routine
	jmp	.end

.parse:
	; set pointer to dynamic section
	mov	r13,	qword [r13 + LIB_ELF_STRUCTURE_SECTION.file_offset]
	add	r13,	qword [rsp]

.library:
	; end of entries?
	cmp	qword [r13 + LIB_ELF_STRUCTURE_SECTION_DYNAMIC.type],	EMPTY
	je	.end	; yes

	; library needed?
	cmp	qword [r13 + LIB_ELF_STRUCTURE_SECTION_DYNAMIC.type],	LIB_ELF_SECTION_DYNAMIC_TYPE_needed
	jne	.omit

	; preserve original registers
	push	rcx
	push	rsi

	; set pointer to library name
	add	rsi,	qword [r13 + LIB_ELF_STRUCTURE_SECTION_DYNAMIC.offset]

	; calculate string length
	call	lib_string_length

	; load library
	call	kernel_library_load

	; restore original registers
	pop	rsi
	pop	rcx


	; error while loading library?
	jc	.end	; yes

.omit:
	; next entry from list
	add	r13,	LIB_ELF_STRUCTURE_SECTION_DYNAMIC.SIZE

	; continue
	jmp	.library

.end:
	; restore original registers
	pop	r13
	pop	r14
	pop	rsi
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - length of string in Bytes
;	rsi - pointer to function name string
; out:
;	rax - pointer to library function entry
;	CF - set if function doesn't found
kernel_library_function:
	; preserve original registers
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r13
	push	r14

	; search from first entry
	xor	ebx,	ebx

	; set pointer to begining of library entries
	mov	r14,	qword [kernel_environment_base_address]
	mov	r14,	qword [r14 + KERNEL_STRUCTURE.library_base_address]

.library:
	; entry configured?
	cmp	word [r14 + KERNEL_LIBRARY_STRUCTURE.flags],	KERNEL_LIBRARY_FLAG_active
	je	.library_parse	; yes

.library_next:
	; move pointer to next entry
	add	r14,	KERNEL_LIBRARY_STRUCTURE.SIZE

	; end of library structure?
	inc	ebx
	cmp	ebx,	KERNEL_LIBRARY_limit
	jb	.library	; no

	; free entry not found
	stc

	; end of routine
	jmp	.end

.library_parse:
	; number of entries in symbol table
	mov	dx,	word [r14 + KERNEL_LIBRARY_STRUCTURE.symbol_limit]

	; retrieve pointer to symbol table
	mov	r13,	qword [r14 + KERNEL_LIBRARY_STRUCTURE.symbol]

.symbol:
	; set pointer to function name
	mov	edi,	dword [r13 + LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.name_offset]
	add	rdi,	qword [r14 + KERNEL_LIBRARY_STRUCTURE.string]

	; strings name are exact length?
	cmp	byte [rdi + rcx],	STATIC_ASCII_TERMINATOR
	je	.symbol_name	; yes

.symbol_next:
	; move pointer to next entry
	add	r13,	LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.SIZE

	; end of dynamic symbols?
	sub	dx,	LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.SIZE
	jnz	.symbol	; no

	; check next library
	jmp	.library_next

.symbol_name:
	; strings are equal in name?
	call	lib_string_compare
	jc	.symbol_next	; no

	; return function address
	mov	rax,	qword [r13 + LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.address]
	add	rax,	qword [r14 + KERNEL_LIBRARY_STRUCTURE.address]

.end:
	; restore original registers
	pop	r14
	pop	r13
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	cl - length of name
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
	push	r9
	push	r11
	push	r12
	push	r13
	push	r15
	push	rsi
	push	rcx
	push	r14

	; library already loaded?
	call	kernel_library_find
	jnc	.exist	; yes

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

	; prepare error code
	mov	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE],	LIB_SYS_ERROR_undefinied

	; import all depended libraries
	call	kernel_library_import
	jc	.error_level_file	; no enough memory or library not found

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

	; aquire memory space inside library environment
	mov	r9,	qword [r8 + KERNEL_STRUCTURE.library_memory_map_address]
	call	kernel_memory_acquire
	jc	.error_level_file	; no enough memory

	; convert page number to logical address
	shl	rdi,	STATIC_PAGE_SIZE_shift

	; prepare space for file content
	mov	rax,	rdi
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write
	mov	r11,	qword [r8 + KERNEL_STRUCTURE.page_base_address]
	call	kernel_page_alloc
	jc	.error_level_aquire	; no enough memory

	; preserve library space size
	mov	r15,	rcx

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

	; retrieve information about:
	; - symbol table
	; - string table

	; number of entries in section header
	movzx	ecx,	word [r13 + LIB_ELF_STRUCTURE.section_entry_count]

	; set pointer to begining of section header
	mov	rsi,	qword [r13 + LIB_ELF_STRUCTURE.section_table_position]
	add	rsi,	r13

.section:
	; function string table?
	cmp	dword [rsi + LIB_ELF_STRUCTURE_SECTION.type],	LIB_ELF_SECTION_TYPE_string_table
	jne	.no_string_table

	; first string table is for functions
	cmp	qword [r14 + KERNEL_LIBRARY_STRUCTURE.string],	EMPTY
	jnz	.no_string_table	; not a function string table

	; preserve pointer to string table
	mov	rbx,	qword [rsi + LIB_ELF_STRUCTURE_SECTION.virtual_address]
	add	rbx,	rdi
	mov	qword [r14 + KERNEL_LIBRARY_STRUCTURE.string],	rbx

.no_string_table:
	; symbol table?
	cmp	dword [rsi + LIB_ELF_STRUCTURE_SECTION.type],	LIB_ELF_SECTION_TYPE_symbol_table
	jne	.no_symbol_table

	; preserve pointer to symbol table
	mov	rbx,	qword [rsi + LIB_ELF_STRUCTURE_SECTION.virtual_address]
	add	rbx,	rdi
	mov	qword [r14 + KERNEL_LIBRARY_STRUCTURE.symbol],	rbx

	; and entries limit
	push	qword [rsi + LIB_ELF_STRUCTURE_SECTION.size_byte]
	pop	qword [r14 + KERNEL_LIBRARY_STRUCTURE.symbol_limit]

.no_symbol_table:
	; move pointer to next section entry
	add	rsi,	LIB_ELF_STRUCTURE_SECTION.SIZE

	; end of library structure?
	dec	ecx
	jnz	.section	; no

	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; preserve library content pointer and size in pages
	mov	qword [r14 + KERNEL_LIBRARY_STRUCTURE.address],	rdi
	mov	word [r14 + KERNEL_LIBRARY_STRUCTURE.size_page],	r15w

	; share access to library content space for processes (read-only)
	mov	rax,	rdi
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_library
	mov	rcx,	r15
	call	kernel_page_flags

	; release space of loaded file
	mov	rcx,	r12
	mov	rdi,	r13
	call	kernel_memory_release

	; register library name and length

	; length in characters
	mov	rcx,	qword [rsp + STATIC_QWORD_SIZE_byte]
	mov	byte [r14 + KERNEL_LIBRARY_STRUCTURE.length],	cl

	; name
	mov	rsi,	qword [rsp + (STATIC_QWORD_SIZE_byte << STATIC_MULTIPLE_BY_2_shift)]
	lea	rdi,	[r14 + KERNEL_LIBRARY_STRUCTURE.name]
	rep	movsb

.exist:
	; return pointer to library entry
	mov	qword [rsp],	r14

.end:
	; restore original registers
	pop	r14
	pop	rcx
	pop	rsi
	pop	r15
	pop	r13
	pop	r12
	pop	r11
	pop	r9
	pop	r8
	pop	rbp
	pop	rdi
	pop	rdx
	pop	rbx
	pop	rax

	; return from routine
	ret

.error_level_aquire:
	; first page of acquired space
	shr	rax,	STATIC_PAGE_SIZE_shift

.error_level_aquire_release:
	; release first page of space
	bts	qword [r9],	rax

	; next page?
	inc	rax
	dec	rcx
	jnz	.error_level_aquire_release	; yes

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