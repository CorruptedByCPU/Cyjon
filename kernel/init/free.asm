;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_free:
	;-----------------------------------------------------------------------
	; after last AP initialization, we can include bootloader memory
	; to binary memory map and use it freely
	;-----------------------------------------------------------------------

	; memory map response structure
	mov	rsi,	qword [kernel_limine_memmap_request + LIMINE_MEMMAP_REQUEST.response]

	; first entry of memory map
	xor	ebx,	ebx
	mov	rdx,	qword [rsi + LIMINE_MEMMAP_RESPONSE.entries]

	; array for areas properties
	mov	rbp,	rsp

.next:
	; retrieve entry address
	mov	rdi,	qword [rdx + rbx * STD_PTR_SIZE_byte]

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

	; amount of freed up pages
	xor	eax,	eax

.area:
	; end of array?
	cmp	rsp,	rbp
	je	.end	; yes

	; area size in pages
	pop	rcx
	shr	rcx,	STD_PAGE_SIZE_shift

	; area position
	mov	rdi,	qword [rsp]
	or	rdi,	qword [kernel_page_mirror]

	; clean up
	call	kernel_page_clean_few

.lock:
	; request an exclusive access
	mov	dl,	LOCK
	xchg	byte [r8 + KERNEL.memory_semaphore],	dl

	; assigned?
	test	dl,	dl
	jnz	.lock	; no

	; extend binary memory map of those area pages
	add	qword [r8 + KERNEL.page_total],	rcx
	add	qword [r8 + KERNEL.page_available],	rcx

	; amount of freed up pages
	add	rax,	rcx

	; first page number of area
	pop	rdx
	shr	rdx,	STD_PAGE_SIZE_shift

.register:
	; register inside binary memory map
	bts	qword [r9],	rdx

	; next page
	inc	rdx

	; entire space is registered?
	dec	rcx
	jnz	.register	; no

	; release access
	mov	byte [r8 + KERNEL.memory_semaphore],	UNLOCK

	; next area from array
	jmp	.area

.end:
	; prefix
	mov	ecx,	kernel_log_prefix_end - kernel_log_prefix
	mov	rsi,	kernel_log_prefix
	call	driver_serial_string

	; convert pages to KiB
	shl	rax,	STD_MULTIPLE_BY_4_shift

	; show amount of released memory
	mov	ebx,	STD_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx	; no prefix
	call	driver_serial_value
	mov	ecx,	kernel_log_free_end - kernel_log_free
	mov	rsi,	kernel_log_free
	call	driver_serial_string

	; reload BSP processor
	jmp	kernel_init_ap