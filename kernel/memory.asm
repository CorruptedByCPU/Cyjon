;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; out:
;	CF - set if not available
;	rdi - pointer to allocated page (physical address)
kernel_memory_alloc_page:
	; preserve original registers
	push	rcx

	; alloc only 1 page
	mov	ecx,	STATIC_PAGE_SIZE_page
	call	kernel_memory_alloc
	jc	.error	; no enough memory, really? ok

	; convert page address to physical area
	mov	rcx,	~KERNEL_PAGE_mirror
	and	rdi,	rcx

.error:
	; restore original registers
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - length of area in pages
; out:
;	CF - set if not available
;	rdi - pointer to allocated area (logical address)
kernel_memory_alloc:
	; preserve original registers
	push	rax
	push	rbx
	push	rsi
	push	r8
	push	rcx

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; by default there is no available space
	xor	edi,	edi

.lock:
	; request an exclusive access
	mov	al,	LOCK
	lock xchg	byte [r8 + KERNEL_STRUCTURE.memory_semaphore],	al

	; assigned?
	test	al,	al
	jnz	.lock	; no

	; required area might be available?
	cmp	rcx,	qword [r8 + KERNEL_STRUCTURE.page_available]
	ja	.error	; no

	; start searching from first page of binary memory map
	xor	eax,	eax
	mov	rsi,	qword [r8 + KERNEL_STRUCTURE.memory_base_address]

.new:
	; start of the considered space
	mov	rbx,	rax

	; length of considered space
	xor	ecx,	ecx

.check:
	; check
	bt	qword [rsi],	rax

	; next page from area and current its length
	inc	rax
	inc	rcx

	; continuity ensured?
	jnc	.new	; no

	; area located?
	cmp	rcx,	qword [rsp]
	je	.found	; yes

	; end of binary memory map?
	cmp	rax,	qword [r8 + KERNEL_STRUCTURE.page_limit]
	je	.error	; yes

	; conitnue search
	jmp	.check

.found:
	; first page of located area
	mov	rax,	rbx

.mark:
	; mark page as reserved
	btr	qword [rsi],	rax

	; next page of area
	inc	rax

	; continue with reservation?
	dec	rcx
	jnz	.mark	; tes

	; convert page number to its logical address
	shl	rbx,	STATIC_PAGE_SIZE_shift
	mov	rdi,	KERNEL_PAGE_mirror
	add	rdi,	rbx

	; allocated successful
	clc
	jmp	.end

.error:
	; operation failed
	stc

.end:
	; release access
	mov	byte [r8 + KERNEL_STRUCTURE.memory_semaphore],	UNLOCK
	
	; restore original registers
	pop	rcx
	pop	r8
	pop	rsi
	pop	rbx
	pop	rax

	; return from routine
	ret