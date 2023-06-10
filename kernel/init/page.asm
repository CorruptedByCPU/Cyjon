;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	r8 - kernel environment variables/rountines base address
kernel_init_page:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r11

	; every registered space inside paging arrays should be full operational
	; by kernel environment
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write;

	; assign page for PML4 array and store it
	call	kernel_memory_alloc_page
	mov	qword [r8 + KERNEL_STRUCTURE.page_base_address],	rdi

	; all paging procedures use R11 register for PML4 address
	mov	r11,	rdi

	;-----------------------------------------------------------------------
	; inside our new paging structure, we need to have access to all
	; memory space, that could/will be used in future, so:
	;
	; LIMINE_MEMMAP_USABLE
	; LIMINE_MEMMAP_KERNEL_AND_MODULES
	; LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE
	; LIMINE_MEMMAP_FRAMEBUFFER
	;-----------------------------------------------------------------------

	; first entry of memory map privded by Limine
	xor	ecx,	ecx
	mov	rax,	qword [kernel_limine_memmap_request + LIMINE_MEMMAP_REQUEST.response]
	mov	rdi,	qword [rax + LIMINE_MEMMAP_RESPONSE.entry]

.entry:
	; retrieve entry address
	mov	rsi,	qword [rdi + rcx * STATIC_PTR_SIZE_byte]

	; type of LIMINE_MEMMAP_USABLE?
	cmp	qword [rsi + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_USABLE
	je	.map	; yes

	; type of LIMINE_MEMMAP_KERNEL_AND_MODULES?
	cmp	qword [rsi + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_KERNEL_AND_MODULES
	je	.map	; yes

	; type of LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE?
	cmp	qword [rsi + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE
	je	.map	; yes

	; type of LIMINE_MEMMAP_FRAMEBUFFER?
	cmp	qword [rsi + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_FRAMEBUFFER
	jne	.next	; no

.map:
	; preserve original registers
	push	rax
	push	rcx

	; size of space in pages
	mov	rcx,	qword [rsi + LIMINE_MEMMAP_ENTRY.length]
	shr	rcx,	STATIC_PAGE_SIZE_shift

	; map physical space to its High-Half mirror
	mov	rax,	KERNEL_PAGE_mirror
	mov	rsi,	qword [rsi + LIMINE_MEMMAP_ENTRY.base]
	or	rax,	rsi
	call	kernel_page_map

	; restore original registers
	pop	rcx
	pop	rax

.next:
	; next entry
	inc	rcx

	; parse next entry?
	cmp	rcx,	qword [rax + LIMINE_MEMMAP_RESPONSE.entry_count]
	jne	.entry	; yes

	;-----------------------------------------------------------------------
	; we need access to parsed ACPI tables (LAPIC, I/O APIC)
	;-----------------------------------------------------------------------

	; every controller space is about 4096 Bytes
	mov	ecx,	STATIC_PAGE_SIZE_page

	; map LAPIC controller space
	mov	rax,	KERNEL_PAGE_mirror
	mov	rsi,	qword [r8 + KERNEL_STRUCTURE.lapic_base_address]
	or	rax,	rsi
	call	kernel_page_map

	; map I/O APIC controller space
	mov	rax,	KERNEL_PAGE_mirror
	mov	rsi,	qword [r8 + KERNEL_STRUCTURE.io_apic_base_address]
	or	rax,	rsi
	call	kernel_page_map

	; map HPET controller space
	mov	rax,	KERNEL_PAGE_mirror
	mov	rsi,	qword [r8 + KERNEL_STRUCTURE.hpet_base_address]
	or	rax,	rsi
	call	kernel_page_map

	;-----------------------------------------------------------------------
	; kernel environment needs its own stack :)
	;-----------------------------------------------------------------------

	; alloc context stack for kernel environment
	mov	rax,	KERNEL_TASK_STACK_address
	mov	ecx,	KERNEL_TASK_STACK_SIZE_page
	call	kernel_page_alloc

	;-----------------------------------------------------------------------
	; last part of paging initialization
	; map kernel sections with proper privileges
	;-----------------------------------------------------------------------

	; kernel address available?
	cmp	qword [kernel_limine_kernel_address_request + LIMINE_KERNEL_FILE_ADDRESS_REQUEST.response],	EMPTY
	je	.error	; no

	; kernel file available?
	cmp	qword [kernel_limine_kernel_file_request + LIMINE_KERNEL_FILE_REQUEST.response],	EMPTY
	je	.error	; no

	; get pointer to kernel address response
	mov	rdx,	qword [kernel_limine_kernel_address_request + LIMINE_KERNEL_FILE_ADDRESS_REQUEST.response]

	; get pointer to kernel file location response
	mov	rdi,	qword [kernel_limine_kernel_file_request + LIMINE_KERNEL_FILE_REQUEST.response]
	mov	rdi,	qword [rdi + LIMINE_KERNEL_FILE_RESPONSE.kernel_file]
	mov	rdi,	qword [rdi + LIMINE_FILE.address]

	; number of hedaers in ELF structure
	mov	cx,	word [rdi + LIB_ELF_STRUCTURE.header_entry_count]

	; move pointer to first header entry
	add	rdi,	qword [rdi + LIB_ELF_STRUCTURE.header_table_position]

.header:
	; entry doesn't have type set?
	cmp	byte [rdi + LIB_ELF_STRUCTURE_HEADER.type],	EMPTY
	je	.leave	; yes

	; entry have EMPTY length?
	cmp	byte [rdi + LIB_ELF_STRUCTURE_HEADER.memory_size],	EMPTY
	je	.leave	; yes

	; preserve original registers
	push	rcx

	; segment length
	mov	rcx,	qword [rdi + LIB_ELF_STRUCTURE_HEADER.virtual_address]
	add	rcx,	qword [rdi + LIB_ELF_STRUCTURE_HEADER.memory_size]
	add	rcx,	~STATIC_PAGE_mask	; align up to page boundaries
	and	cx,	STATIC_PAGE_mask
	shr	rcx,	STATIC_PAGE_SIZE_shift	; convert to pages
	movzx	rcx,	cx	; limits kernel size to 256 MiB, not enough?

	; segment offset
	mov	rsi,	~KERNEL_BASE_location
	and	rsi,	qword [rdi + LIB_ELF_STRUCTURE_HEADER.virtual_address]
	and	si,	STATIC_PAGE_mask

	; kernel segment target
	mov	rax,	KERNEL_BASE_location
	add	rax,	rsi

	; kernel segment source
	add	rsi,	qword [rdx + LIMINE_KERNEL_FILE_ADDRESS_RESPONCE.physical_base]

	; map segment to kernel paging arrays
	call	kernel_page_map

	; restore original registers
	pop	rcx

.leave:
	; next entry
	add	rdi,	LIB_ELF_STRUCTURE_HEADER.SIZE

	; some entries left?
	dec	cx
	jns	.header	; yes

.end:
	; correct pointers of environment variables
	mov	rax,	KERNEL_PAGE_mirror
	or	qword [r8 + KERNEL_STRUCTURE.io_apic_base_address],	rax
	or	qword [r8 + KERNEL_STRUCTURE.lapic_base_address],	rax
	or	qword [r8 + KERNEL_STRUCTURE.memory_base_address],	rax
	or	qword [r8 + KERNEL_STRUCTURE.page_base_address],	rax

	; and kernel environment variables/routines itself
	or	qword [kernel_environment_base_address],	rax
	or	r8,	rax	; with pointer
	or	r9,	rax

	; share page functions with daemons
	mov	qword [r8 + KERNEL_STRUCTURE.page_deconstruction],	kernel_page_deconstruction

	; we are ready to switch paging arrays to new one

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

.error:
	; kernel file is not available
	mov	ecx,	kernel_log_kernel_end - kernel_log_kernel
	mov	rsi,	kernel_log_kernel
	call	driver_serial_string

	; hold the door
	jmp	$
