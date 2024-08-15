;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_memory:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; global kernel environment variables/functions/rountines
	mov	r8,	qword [kernel]

	; place binary memory map after global kernel environment variables/functions/rountines (aligned to page boundaries)
	mov	qword [r8 + KERNEL.memory_base_address],	r8
	add	qword [r8 + KERNEL.memory_base_address],	(KERNEL.SIZE + ~STD_PAGE_mask) & STD_PAGE_mask

	; properties of binary memory map
	mov	r9,	qword [r8 + KERNEL.memory_base_address]

	;----------------------------------------------------------------------

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
	mov	rax,	qword [rsi + rcx * STD_PTR_SIZE_byte]

	; USABLE, BOOTLOADER_RECLAIMABLE, KERNEL_AND_MODULES or ACPI_RECLAIMABLE memory area?
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_USABLE
	je	.parse
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE
	je	.parse
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_KERNEL_AND_MODULES
	je	.parse
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_ACPI_RECLAIMABLE
	jne	.entry	; next entry

.parse:
	; calculate farthest part of memory area for use
	mov	rdx,	qword [rax + LIMINE_MEMMAP_ENTRY.base]
	add	rdx,	qword [rax + LIMINE_MEMMAP_ENTRY.length]
	shr	rdx,	STD_SHIFT_PAGE

	; further than previous?
	cmp	rdx,	qword [r8 + KERNEL.page_limit]
	jb	.below	; no

	; remember area
	mov	qword [r8 + KERNEL.page_limit],	rdx

.below:
	; keep number of pages registered in the binary memory map
	mov	rdx,	qword [rax + LIMINE_MEMMAP_ENTRY.length]
	shr	rdx,	STD_SHIFT_PAGE
	add	qword [r8 + KERNEL.page_total],	rdx

	; USABLE memory area?
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_USABLE
	jne	.entry	; no, next entry

	; add memory area to available memory
	add	qword [r8 + KERNEL.page_available],	rdx

	; first page number of area
	mov	rdi,	qword [rax + LIMINE_MEMMAP_ENTRY.base]
	shr	rdi,	STD_SHIFT_PAGE

.fill:
	; register inside binary memory map
	bts	qword [r9],	rdi

	; next page
	inc	rdi

	; entire area is registered?
	dec	rdx
	jnz	.fill	; no

	; next entry
	jmp	.entry

.done:
	; round up kernel page limit up to Byte
	mov	rax,	qword [r8 + KERNEL.page_limit]
	xor	edx,	edx
	mov	rcx,	STD_MOVE_BYTE
	div	rcx
	jz	.limited	; already done

	; apply new limit
	add	qword [r8 + KERNEL.page_limit],	STD_MOVE_BYTE
	sub	qword [r8 + KERNEL.page_limit],	rdx

.limited:
	; first page number of reserved area (global kernel environment variables/functions/rountines and binary memory map)
	mov	rdi,	~KERNEL_PAGE_mirror
	and	rdi,	r8
	shr	rdi,	STD_SHIFT_PAGE

	; calculate length of reserved area in pages
	mov	rdx,	qword [r8 + KERNEL.page_limit]
	shr	rdx,	STD_SHIFT_8	; convert Bits to Bytes
	inc	rdx			; add semaphore area
	add	rdx,	~STD_PAGE_mask	; align up to page boundary
	add	rdx,	r9		; add position of binary memory map
	mov	rax,	~KERNEL_PAGE_mirror
	and	rdx,	rax		; convert to physical address
	shr	rdx,	STD_SHIFT_PAGE	; change to pages

	; so, our available pages are less by
	sub	rdx,	rdi
	sub	qword [r8 + KERNEL.page_available],	rdx

.mark:
	; mark page as unavailable
	btr	qword [r9],	rdi

	; next page
	inc	rdi

	; unavailable space marked?
	dec	rdx
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