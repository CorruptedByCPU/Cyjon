;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	r8 - pointer to kernel environment variables/routines
;	r9 - pointer to binary memory map
kernel_init_free:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp

	;-----------------------------------------------------------------------
	; after last AP initialization, we can include bootloader memory
	; to binary memory map and use it freely
	;-----------------------------------------------------------------------

	; memory map response structure
	mov	rsi,	qword [kernel_limine_memmap_request + LIMINE_MEMMAP_REQUEST.response]

	; first entry of memory map
	xor	ebx,	ebx
	mov	rdx,	qword [rsi + LIMINE_MEMMAP_RESPONSE.entry]

	; array for areas properties
	mov	rbp,	rsp

.next:
	; retrieve entry address
	mov	rdi,	qword [rdx + rbx * STATIC_PTR_SIZE_byte]

	; type of LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE?
	cmp	qword [rdi + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE
	jne	.omit	; no

	; remember adrea position and length
	push	qword [rdi + LIMINE_MEMMAP_ENTRY.base]
	push	qword [rdi + LIMINE_MEMMAP_ENTRY.length]

.omit:
	; next entry
	inc	rbx

	; end of entries?
	cmp	rbx,	qword [rsi + LIMINE_MEMMAP_RESPONSE.entry_count]
	jne	.next	; no

	;-----------------------------------------------------------------------
	; at this point, we CANNOT use any Limine structure anymore!
	; thats why we created array of RECLAIMABLE areas on stack...
	;-----------------------------------------------------------------------

.area:
	; end of array?
	cmp	rsp,	rbp
	je	.end	; yes

	; area size in pages
	pop	rcx
	shr	rcx,	STATIC_PAGE_SIZE_shift

	; area position
	mov	rdi,	KERNEL_PAGE_mirror
	or	rdi,	qword [rsp]

	; clean up
	call	kernel_page_clean_few

.lock:
	; request an exclusive access
	mov	al,	LOCK
	lock xchg	byte [r8 + KERNEL_STRUCTURE.memory_semaphore],	al

	; assigned?
	test	al,	al
	jnz	.lock	; no

	; extend binary memory map of those area pages
	add	qword [r8 + KERNEL_STRUCTURE.page_total],	rcx
	add	qword [r8 + KERNEL_STRUCTURE.page_available],	rcx

	; first page number of area
	pop	rax
	shr	rax,	STATIC_PAGE_SIZE_shift

.register:
	; register inside binary memory map
	bts	qword [r9],	rax

	; next page
	inc	rax

	; entire space is registered?
	dec	rcx
	jnz	.register	; no

	; release access
	mov	byte [r8 + KERNEL_STRUCTURE.memory_semaphore],	UNLOCK

	; next area from array
	jmp	.area

.end:
	; restore original registers
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret