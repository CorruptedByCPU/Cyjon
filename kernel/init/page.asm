;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_page:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r11

	; allow all BS/A processors to write on read-only pages inside ring0
	mov	rax,	cr0
	and	rax,	~(1 << 16)
	mov	cr0,	rax

	; alloc 1 page for PML4 kernel environment array
	mov	ecx,	TRUE
	call	kernel_memory_alloc

	; preserve pointer inside KERNEL environment
	mov	qword [r8 + KERNEL.page_base_address],	rdi

	; default flags of every page
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write;

	; all paging procedures use R11 register for PML4 address
	mov	r11,	rdi

	;---------------------------------------------------------------------

	; properties of memory map response
	mov	rsi,	qword [kernel_limine_memmap_request + LIMINE_MEMMAP_REQUEST.response]

	; amount of entries inside memory map
	mov	rcx,	qword [rsi + LIMINE_MEMMAP_RESPONSE.entry_count]

	; list of memory map entires
	mov	rsi,	qword [rsi + LIMINE_MEMMAP_RESPONSE.entries]

.entry:
	; parse "next" entry?
	dec	rcx
	js	.done	; no

	; retrieve entry
	mov	rax,	qword [rsi + rcx * STD_SIZE_PTR_byte]

	; USABLE, BOOTLOADER_RECLAIMABLE, KERNEL_AND_MODULES, FRAMEBUFFER or ACPI_RECLAIMABLE memory area?
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_USABLE
	je	.parse
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE
	je	.parse
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_KERNEL_AND_MODULES
	je	.parse
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_FRAMEBUFFER
	je	.parse
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_ACPI_RECLAIMABLE
	jne	.entry	; next entry

.parse:
	; preserve original registers
	push	rcx
	push	rsi

	; size of area in pages
	mov	rcx,	qword [rax + LIMINE_MEMMAP_ENTRY.length]
	shr	rcx,	STD_SHIFT_PAGE

	; physical area to logical area
	mov	rsi,	qword [rax + LIMINE_MEMMAP_ENTRY.base]
	mov	rax,	KERNEL_PAGE_mirror
	or	rax,	rsi

	; map memory area to kernel paging arrays
	call	kernel_page_map

	; restore original registers
	pop	rsi
	pop	rcx

	; next entry
	jmp	.entry

.done:
	;---------------------------------------------------------------------

	; every controller space is about 4096 Bytes
	mov	ecx,	STD_PAGE_page

	; map LAPIC controller space
	mov	rax,	qword [r8 + KERNEL.lapic_base_address]
	mov	rsi,	~KERNEL_PAGE_mirror
	and	rsi,	rax
	call	kernel_page_map

	; map I/O APIC controller space
	mov	rax,	qword [r8 + KERNEL.io_apic_base_address]
	mov	rsi,	~KERNEL_PAGE_mirror
	and	rsi,	rax
	call	kernel_page_map

	; now something harder ------------------------------------------------

	; kernel file properties
	mov	rdi,	qword [kernel_limine_kernel_file_request + LIMINE_KERNEL_FILE_REQUEST.response]
	mov	rdi,	qword [rdi + LIMINE_KERNEL_FILE_RESPONSE.kernel_file]
	mov	rdi,	qword [rdi + LIMINE_FILE.address]

	; number of hedaers in ELF structure
	mov	cx,	word [rdi + LIB_ELF_STRUCTURE.h_entry_count]

	; move pointer to first header entry
	add	rdi,	qword [rdi + LIB_ELF_STRUCTURE.headers_offset]

	; get pointer to kernel address response
	mov	rdx,	qword [kernel_limine_kernel_address_request + LIMINE_KERNEL_FILE_ADDRESS_REQUEST.response]

.header:
	; entry doesn't have type set?
	cmp	byte [rdi + LIB_ELF_STRUCTURE_HEADER.type],	EMPTY
	je	.next	; yes

	; entry have EMPTY length?
	cmp	byte [rdi + LIB_ELF_STRUCTURE_HEADER.memory_size],	EMPTY
	je	.next	; yes

	; preserve original registers
	push	rcx

	; segment length
	mov	rcx,	~KERNEL_BASE_address
	and	rcx,	qword [rdi + LIB_ELF_STRUCTURE_HEADER.virtual_address]
	add	rcx,	qword [rdi + LIB_ELF_STRUCTURE_HEADER.memory_size]
	MACRO_PAGE_ALIGN_UP_REGISTER	rcx
	shr	rcx,	STD_SHIFT_PAGE	; convert to pages

	; segment offset
	mov	rsi,	~KERNEL_BASE_address
	and	rsi,	qword [rdi + LIB_ELF_STRUCTURE_HEADER.virtual_address]
	and	si,	STD_PAGE_mask

	; kernel segment target
	mov	rax,	KERNEL_BASE_address
	add	rax,	rsi

	; kernel segment source
	add	rsi,	qword [rdx + LIMINE_KERNEL_FILE_ADDRESS_RESPONCE.physical_base]

	; default flags of kernel segment
	mov	bx,	KERNEL_PAGE_FLAG_present

	; update with additional flag (if exist)
	test	dword [rdi + LIB_ELF_STRUCTURE_HEADER.flags],	LIB_ELF_FLAG_write
	jnz	.default	; no

	; data segment
	or	bx,	KERNEL_PAGE_FLAG_write

.default:
	; map segment to kernel paging arrays
	call	kernel_page_map

	; restore original registers
	pop	rcx

.next:
	; next entry
	add	rdi,	LIB_ELF_STRUCTURE_HEADER.SIZE

	; some entries left?
	dec	cx
	jns	.header	; yes

.end:
	;---------------------------------------------------------------------

	; and last thing, create kernel stack area
	mov	rax,	KERNEL_STACK_address
	mov	ecx,	KERNEL_STACK_page
	call	kernel_page_alloc

	; restore original registers
	pop	r11
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret