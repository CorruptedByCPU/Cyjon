;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; out:
;	r8 - pointer to kernel environment variables/routines
kernel_init_memory:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; memory map available?
	cmp	qword [kernel_limine_memmap_request + LIMINE_MEMMAP_REQUEST.response],	EMPTY
	je	.error	; no

	;-----------------------------------------------------------------------
	; below instructions will clean up all areas of memory marked as USABLE
	; and find of best place to store our kernel environment variables/routines
	; & binary memory map
	;-----------------------------------------------------------------------

	; force consistency of available memory space for use (clean it up)
	xor	eax,	eax	; and remember largest continous space in Bytes

	; memory map response structure
	mov	rsi,	qword [kernel_limine_memmap_request + LIMINE_MEMMAP_REQUEST.response]

	; first entry of memory map
	xor	ebx,	ebx
	mov	rdx,	qword [rsi + LIMINE_MEMMAP_RESPONSE.entry]

.next:
	; retrieve entry address
	mov	rdi,	qword [rdx + rbx * STATIC_PTR_SIZE_byte]

	; type of LIMINE_MEMMAP_USABLE?
	cmp	qword [rdi + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_USABLE
	jne	.omit	; no

	; this entry is larger than previous?
	cmp	qword [rdi + LIMINE_MEMMAP_ENTRY.length],	rax
	jng	.clean_up	; no

	; preserve logical address of largest continous memory space
	mov	rax,	qword [rdi + LIMINE_MEMMAP_ENTRY.base]
	mov	qword [kernel_environment_base_address], rax

	; and its size in Bytes
	mov	rax,	qword [rdi + LIMINE_MEMMAP_ENTRY.length]

.clean_up:
	; size of area in pages
	mov	rcx,	qword [rdi + LIMINE_MEMMAP_ENTRY.length]
	shr	rcx,	STATIC_PAGE_SIZE_shift

	; clean memory area
	mov	rdi,	qword [rdi + LIMINE_MEMMAP_ENTRY.base]
	call	kernel_page_clean_few

.omit:
	; next entry
	inc	rbx

	; end of entries?
	cmp	rbx,	qword [rsi + LIMINE_MEMMAP_RESPONSE.entry_count]
	jne	.next	; no

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; place binary memory map after kernel environment variables/rountines (aligned to page boundaries)
	mov	r9,	KERNEL_STRUCTURE.SIZE
	add	r9,	~STATIC_PAGE_mask
	and	r9,	STATIC_PAGE_mask
	add	r9,	r8

	; store pointer inside kernel environment
	mov	qword [r8 + KERNEL_STRUCTURE.memory_base_address],	r9

	;-----------------------------------------------------------------------
	; next we will register every area marked as LIMINE_MEMMAP_USABLE
	; inside our binary memory map
	;
	; about LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE,
	; we will register that memory areas, after kernel environment initializations
	;-----------------------------------------------------------------------

	; memory map response structure
	mov	rsi,	qword [kernel_limine_memmap_request + LIMINE_MEMMAP_REQUEST.response]

	; first entry of memory map
	xor	ebx,	ebx
	mov	rdx,	qword [rsi + LIMINE_MEMMAP_RESPONSE.entry]

.usable:
	; retrieve entry address
	mov	rdi,	qword [rdx + rbx * STATIC_PTR_SIZE_byte]

	; type of LIMINE_MEMMAP_USABLE?
	cmp	qword [rdi + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_USABLE
	jne	.leave	; no

	; length of binary memory map in pages (and available too)
	mov	rcx,	qword [rdi + LIMINE_MEMMAP_ENTRY.length]
	shr	rcx,	STATIC_PAGE_SIZE_shift
	add	qword [r8 + KERNEL_STRUCTURE.page_total],	rcx
	add	qword [r8 + KERNEL_STRUCTURE.page_available],	rcx

	; limine assures us that all entries are sorted by addresses (ascending)
	; so we can and need to store the address of the end of farthest entry in memory
	; of those types to calculate size of binary memory map
	mov	rax,	qword [rdi + LIMINE_MEMMAP_ENTRY.base]
	add	rax,	qword [rdi + LIMINE_MEMMAP_ENTRY.length]
	mov	qword [r8 + KERNEL_STRUCTURE.page_limit],	rax

	; first page number of area
	mov	rax,	qword [rdi + LIMINE_MEMMAP_ENTRY.base]
	shr	rax,	STATIC_PAGE_SIZE_shift

.register:
	; register inside binary memory map
	bts	qword [r9],	rax

	; next page
	inc	rax

	; entire space is registered?
	dec	rcx
	jnz	.register	; no

.leave:
	; next entry
	inc	rbx

	; end of entries?
	cmp	rbx,	qword [rsi + LIMINE_MEMMAP_RESPONSE.entry_count]
	jne	.usable	; no

	; convert preserved end address of last entry to binary memory map limit in pages
	shr	qword [r8 + KERNEL_STRUCTURE.page_limit], STATIC_PAGE_SIZE_shift

	;-----------------------------------------------------------------------
	; some of those registered pages are already used, and You know by who...
	; "kernel environment variables/routines and binary memory map"
	; mark those pages as unavailable
	;-----------------------------------------------------------------------

	; first page to be marked, thats simple :)
	mov	rbx,	r8
	shr	rbx,	STATIC_PAGE_SIZE_shift

	; and more voyage...
	; length of unavailable space in pages

	; length of binary memory map in Bytes
	mov	rcx,	qword [r8 + KERNEL_STRUCTURE.page_limit]
	shr	rcx,	STATIC_DIVIDE_BY_8_shift

	; sum with binary memory map address
	add	rcx,	r9

	; and substract kernel environment variables/routines address
	sub	rcx,	r8

	; align length to page boundaries and convert to pages
	add	rcx,	~STATIC_PAGE_mask
	shr	rcx,	STATIC_PAGE_SIZE_shift

	; so, our available pages are less by
	sub	qword [r8 + KERNEL_STRUCTURE.page_available],	rcx

.mark:
	; mark page as unavailable
	btr	qword [r9],	rbx

	; next page
	inc	rbx

	; unavailable space marked?
	dec	rcx
	jnz	.mark	; no

	; restore original registers
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret

.error:
	; memory map is not available
	mov	rsi,	kernel_log_memory
	call	driver_serial_string

	; hold the door
	jmp	$