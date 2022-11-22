;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

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
	jne	.available	; yes

	; memory map is not available
	mov	rsi,	kernel_log_memory
	call	driver_serial_string

	; hold the door
	jmp	$

.available:
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
	mov	rax,	KERNEL_PAGE_high_half	; as High-Half
	or	rax,	qword [rdi + LIMINE_MEMMAP_ENTRY.base]
	mov	qword [kernel_environment_base_address], rax

	; and its size in Bytes
	mov	rax,	qword [rdi + LIMINE_MEMMAP_ENTRY.length]

.clean_up:
	; size of area in Pages
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

.entry_end:
	; restore original registers
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret