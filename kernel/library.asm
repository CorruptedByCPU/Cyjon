;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

kernel_library_string_dynstr			db	".dynstr", STATIC_ASCII_TERMINATOR
kernel_library_string_shstrtab			db	".shstrtab", STATIC_ASCII_TERMINATOR
kernel_library_string_got_plt			db	".got.plt", STATIC_ASCII_TERMINATOR

;-------------------------------------------------------------------------------
; in:
;	r13 - pointer to file content
; out:
;	CF is library was not loaded
kernel_library:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi
	push	r13

	; search for STRTAB (function/library names) section of file
	mov	eax,	LIB_ELF_SECTION_TYPE_strtab
	call	kernel_library_section_by_type
	jc	.end	; no external libraries required

	; set STRTAB section pointer in place
	mov	rsi,	qword [rax + LIB_ELF_STRUCTURE_SECTION.file_offset]
	add	rsi,	r13

	; search for DYNAMIC section of file
	mov	eax,	LIB_ELF_SECTION_TYPE_dynamic
	call	kernel_library_section_by_type
	jc	.end	; no external libraries required

	; set STRTAB section pointer in place
	mov	rax,	qword [rax + LIB_ELF_STRUCTURE_SECTION.file_offset]
	add	rax,	r13
	mov	r13,	rax

.library:
	; library required?
	cmp	qword [r13 + LIB_ELF_STRUCTURE_SECTION_DYNAMIC.type],	LIB_ELF_SECTION_DYNAMIC_TYPE_needed
	jne	.end	; no, and no more should be listed

	; preserve original registers
	push	rsi

	; set pointer to library name
	add	rsi,	qword [r13 + LIB_ELF_STRUCTURE_SECTION_DYNAMIC.offset]
	call	lib_string_length

	; library already loaded?
	call	kernel_library_find
	jnc	.next	; yes

	; load library
	call	kernel_library_load

.next:
	; restore original registers
	pop	rsi

	; error while loading library?
	jc	.end	; yes

	; next entry from list
	add	r13,	LIB_ELF_STRUCTURE_SECTION_DYNAMIC.SIZE

	; continue
	jmp	.library

.end:
	; restore original registers
	pop	r13
	pop	rsi
	pop	rcx
	pop	rax

	; return from routine
	ret

;------------------------------------------------------------------------------
; in:
;	eax - type of requested section
;	r13 - pointer to file content
; out:
;	rax - pointer to section properties or garbage if CF is set
;	CF if not found
kernel_library_section_by_type:
	; preserve original registers
	push	rbx
	push	r13

	; amount of entries of section headers
	mov	bx,	word [r13 + LIB_ELF_STRUCTURE.section_entry_count]

	; move pointer to section headers
	add	r13,	qword [r13 + LIB_ELF_STRUCTURE.section_table_position]

.section:
	; exact section type?
	cmp	eax,	dword [r13 + LIB_ELF_STRUCTURE_SECTION.type]
	je	.found	; yes

	; move pointer to next entry of section headers
	add	r13,	LIB_ELF_STRUCTURE_SECTION.SIZE

	; no more entries?
	dec	bx
	jnz	.section	; no

	; section not found
	stc

	; end of routine
	jmp	.end

.found:
	; return section properties
	mov	rax,	r13

.end:
	; restore original registers
	pop	r13
	pop	rbx

	; return from routine
	ret

;------------------------------------------------------------------------------
; in:
;	rsi - pointer to section name (string)
;	r13 - pointer to file content
; out:
;	rax - pointer to section properties or garbage if CF is set
kernel_library_section_by_name:
	; preserve original registers
	push	rbx
	push	rcx
	push	rdi
	push	r13

	; amount of entries of section headers
	mov	bx,	word [r13 + LIB_ELF_STRUCTURE.section_entry_count]

	; section name length
	call	lib_string_length

	; move pointer to section headers
	add	r13,	qword [r13 + LIB_ELF_STRUCTURE.section_table_position]

	; calculate SHSTRTAB offset
	movzx	eax,	bx
	dec	rax	; always last entry
	shl	rax,	STATIC_MULTIPLE_BY_64_shift

	; retrieve pointer to SHSTRTAB section
	mov	rax,	qword [r13 + rax + LIB_ELF_STRUCTURE_SECTION.file_offset]
	add	rax,	qword [rsp]

.section:
	; retrieve section name pointer
	mov	edi,	dword [r13 + LIB_ELF_STRUCTURE_SECTION.name]
	add	rdi,	rax

	; check section name
	call	lib_string_compare
	jc	.next	; different

	; check if section name wasn't part of something else
	test	byte [rdi + rcx],	STATIC_ASCII_TERMINATOR
	jnz	.next	; it is

	; return section properties
	mov	rax,	r13

	; end of routine
	jmp	.end

.next:
	; move pointer to next entry of section headers
	add	r13,	LIB_ELF_STRUCTURE_SECTION.SIZE

	; no more entries?
	dec	bx
	jnz	.section	; no

	; section not found
	stc

.end:
	; restore original registers
	pop	r13
	pop	rdi
	pop	rcx
	pop	rbx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - length of string
;	rsi - pointer to string (name of library)
; out:
;	r14 - pointer to new library entry
;	CF - set if no free entry
kernel_library_add:
	; preserve original registers
	push	rbx
	push	rcx
	push	rsi
	push	r14

	; search from first entry
	xor	ecx,	ecx

	; set pointer to begining of library entries
	mov	r14,	qword [kernel_environment_base_address]
	mov	r14,	qword [r14 + KERNEL_STRUCTURE.library_base_address]

.next:
	; entry is free?
	cmp	word [r14 + KERNEL_LIBRARY_STRUCTURE.flags],	EMPTY
	je	.found	; yes

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
	; mark entry as reserved
	mov	word [r14 + KERNEL_LIBRARY_STRUCTURE.flags],	KERNEL_LIBRARY_FLAG_reserved

	; return entry pointer
	mov	qword [rsp],	r14

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
	cmp	dword [rsi + LIB_ELF_STRUCTURE_SECTION.type],	LIB_ELF_SECTION_TYPE_strtab
	jne	.no_string_table

	; first string table is for functions
	cmp	qword [r14 + KERNEL_LIBRARY_STRUCTURE.strtab],	EMPTY
	jnz	.no_string_table	; not a function string table

	; preserve pointer to string table
	mov	rbx,	qword [rsi + LIB_ELF_STRUCTURE_SECTION.virtual_address]
	add	rbx,	rdi
	mov	qword [r14 + KERNEL_LIBRARY_STRUCTURE.strtab],	rbx

.no_string_table:
	; symbol table?
	cmp	dword [rsi + LIB_ELF_STRUCTURE_SECTION.type],	LIB_ELF_SECTION_TYPE_dynsym
	jne	.no_symbol_table

	; preserve pointer to symbol table
	mov	rbx,	qword [rsi + LIB_ELF_STRUCTURE_SECTION.virtual_address]
	add	rbx,	rdi
	mov	qword [r14 + KERNEL_LIBRARY_STRUCTURE.dynsym],	rbx

	; and entries limit
	push	qword [rsi + LIB_ELF_STRUCTURE_SECTION.size_byte]
	pop	qword [r14 + KERNEL_LIBRARY_STRUCTURE.dynsym_limit]

.no_symbol_table:
	; move pointer to next section entry
	add	rsi,	LIB_ELF_STRUCTURE_SECTION.SIZE

	; end of library structure?
	dec	ecx
	jnz	.section	; no

.end:
	; restore original registers
	pop	r14
	pop	rsi
	pop	rcx
	pop	rbx

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
	; this check below is not necessary

	; entry is active?
	test	word [r14 + KERNEL_LIBRARY_STRUCTURE.flags],	KERNEL_LIBRARY_FLAG_active
	jz	.next	; no

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
	test	word [r14 + KERNEL_LIBRARY_STRUCTURE.flags],	KERNEL_LIBRARY_FLAG_active
	jnz	.library_parse	; yes

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
	mov	dx,	word [r14 + KERNEL_LIBRARY_STRUCTURE.dynsym_limit]

	; retrieve pointer to symbol table
	mov	r13,	qword [r14 + KERNEL_LIBRARY_STRUCTURE.dynsym]

.dynsym:
	; set pointer to function name
	mov	edi,	dword [r13 + LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.name_offset]
	add	rdi,	qword [r14 + KERNEL_LIBRARY_STRUCTURE.strtab]

	; strings name are exact length?
	cmp	byte [rdi + rcx],	STATIC_ASCII_TERMINATOR
	je	.dynsym_name	; yes

.dynsym_next:
	; move pointer to next entry
	add	r13,	LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.SIZE

	; end of dynamic symbols?
	sub	dx,	LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.SIZE
	jnz	.dynsym	; no

	; check next library
	jmp	.library_next

.dynsym_name:
	; strings are equal in name?
	call	lib_string_compare
	jc	.dynsym_next	; no

	; return function address
	mov	rax,	qword [r13 + LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.address]

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
;	rdi - pointer to logical executable space
;	r13 - pointer to file content
kernel_library_local:
	; preserve original registers
	push	rax
	push	rbx
	push	rsi

	; search for DYNSYM section of file
	mov	rsi,	kernel_library_string_dynstr
	call	kernel_library_section_by_name

	; set pointer to dynamic strings
	mov	rsi,	rax

	; search for DYNSYM section of file
	mov	eax,	LIB_ELF_SECTION_TYPE_dynsym
	call	kernel_library_section_by_type

	; set pointer to dynamic symbols
	mov	rbx,	qword [rax + LIB_ELF_STRUCTURE_SECTION.virtual_address]
	add	rbx,	rdi

	; and size on Bytes
	mov	rax,	qword [rax + LIB_ELF_STRUCTURE_SECTION.size_byte]

.local:
	; it's a local function?
	cmp	qword [rbx + LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.address],	EMPTY
	je	.next	; no

	; insert function address to GOT at RCX offset
	add	qword [rbx + LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.address],	rdi

.next:
	; move pointer to next entry
	add	rbx,	LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.SIZE

	; no more entries?
	sub	rax,	LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.SIZE
	jnz	.local	; no

.end:
	; restore original registers
	pop	rsi
	pop	rbx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to logical executable space
;	r13 - pointer to file content
kernel_library_external:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r14
	push	r13

	; we need to locate 4 sections of programm to be able to resolve bindings to functions

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
	mov	r9,	qword [rax + LIB_ELF_STRUCTURE_SECTION.virtual_address]
	add	r9,	rdi

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

	; set pointer to GOT.PLT
	mov	r11,	qword [rax + LIB_ELF_STRUCTURE_SECTION.virtual_address]
	add	r11,	rdi

	; move pointer to first function address entry
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

	; it's a local function?
	cmp	qword [r9 + rax + LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.address],	EMPTY
	je	.function_global	; no

	; retrieve local function correct address
	push	qword [r9 + rax + LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL.address]

	; insert function address to GOT at RCX offset
	pop	qword [r11 + r12 * 0x08]

	; next relocation
	jmp	.function_next

.function_global:
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
	pop	r14
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

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

	; prepare error code
	mov	qword [rsp],	LIB_SYS_ERROR_memory_no_enough

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
	add	rdi,	qword [kernel_library_base_address]

	; prepare space for file content
	mov	rax,	rdi
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_library
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
	; connect libraries (if needed)
	;-----------------------------------------------------------------------
	call	kernel_library_local

	;----------------------------------------------------------------------

	; import all depended libraries
	call	kernel_library
	jc	.error_level_file	; no enough memory or library not found

	; prepare new entry for current library
	call	kernel_library_add
	jc	.error_level_file	; no enough memory

	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; preserve library content pointer and size in pages
	mov	qword [r14 + KERNEL_LIBRARY_STRUCTURE.address],	rdi
	mov	word [r14 + KERNEL_LIBRARY_STRUCTURE.size_page],	r15w

	; share access to library content space for processes (read-only)
	mov	rax,	rdi
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_library
	mov	rcx,	r15
	mov	r11,	qword [r8 + KERNEL_STRUCTURE.page_base_address]
	call	kernel_page_flags

	; register library name and length

	; length in characters
	mov	rcx,	qword [rsp + STATIC_QWORD_SIZE_byte]
	mov	byte [r14 + KERNEL_LIBRARY_STRUCTURE.length],	cl

	; name
	mov	rsi,	qword [rsp + (STATIC_QWORD_SIZE_byte << STATIC_MULTIPLE_BY_2_shift)]
	push	rdi	; preserve library content location
	lea	rdi,	[r14 + KERNEL_LIBRARY_STRUCTURE.name]
	rep	movsb

	; library parsed
	or	word [r14 + KERNEL_LIBRARY_STRUCTURE.flags],	KERNEL_LIBRARY_FLAG_active

	; restore library content location
	pop	rdi

	;-----------------------------------------------------------------------
	; connect libraries (if needed)
	;-----------------------------------------------------------------------
	call	kernel_library_external

	; release space of loaded file
	mov	rsi,	r12
	mov	rdi,	r13
	call	kernel_memory_release

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
	mov	rsi,	r12
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