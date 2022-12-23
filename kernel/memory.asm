;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	rcx - length of area in pages
; out:
;	CF - set if not available
;	rdi - pointer to allocated area (logical address)
kernel_memory_alloc:
	; preserve original registers
	push	rax
	push	r8
	push	r9

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

.lock:
	; request an exclusive access
	mov	al,	LOCK
	lock xchg	byte [r8 + KERNEL_STRUCTURE.memory_semaphore],	al

	; assigned?
	test	al,	al
	jnz	.lock	; no

	; start searching from first page of binary memory map
	mov	r9,	qword [r8 + KERNEL_STRUCTURE.memory_base_address]
	call	kernel_memory_acquire
	jc	.end	; no enough memory

	; convert page number to its logical address
	shl	rdi,	STATIC_PAGE_SIZE_shift
	add	rdi,	qword [kernel_page_mirror]

.end:
	; release access
	mov	byte [r8 + KERNEL_STRUCTURE.memory_semaphore],	UNLOCK

	; restore original registers
	pop	r9
	pop	r8
	pop	rax

	; return from routine
	ret

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
;	rcx - length of space in pages
;	r9 - pointer to binary memory map of process
; out:
;	CF - set if not available
;	rdi - first page number of aquired space
kernel_memory_acquire:
	; preserve original registers
	push	rax
	push	r8
	push	rcx

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; start from first page of binary memory map
	xor	eax,	eax

.new:
	; start of the considered space
	mov	rdi,	rax

	; length of considered space
	xor	ecx,	ecx

.check:
	; check
	bt	qword [r9],	rax

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
	mov	rax,	rdi

.mark:
	; mark page as reserved
	btr	qword [r9],	rax

	; next page of area
	inc	rax

	; continue with reservation?
	dec	rcx
	jnz	.mark	; tes

	; allocated successful
	clc
	jmp	.end

.error:
	; operation failed
	stc

.end:
	; restore original registers
	pop	rcx
	pop	r8
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - length of space in pages
;	rdi - pointer to first page of space
kernel_memory_release:
	; preserve original registers
	push	rax
	push	rcx
	push	rdi

	; we guarantee, clean pages on stack
	call	kernel_page_clean_few

	; convert page address to physical, and offset of memory binary map
	mov	rax,	~KERNEL_PAGE_mirror
	and	rax,	rdi
	shr	rax,	STATIC_PAGE_SIZE_shift

	; put page back to binary memory map
	mov	rdi,	qword [kernel_environment_base_address]
	mov	rdi,	qword [rdi + KERNEL_STRUCTURE.memory_base_address]

.page:
	; release first page of space
	bts	qword [rdi],	rax

	; next page?
	inc	rax
	dec	rcx
	jnz	.page	; yes

	; restore original registers
	pop	rdi
	pop	rcx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - logical page address
kernel_memory_release_page:
	; preserve original registers
	push	rax
	push	rdi

	; we guarantee, clean pages on stack
	call	kernel_page_clean

	; convert page address to physical and offset inside memory binary map
	mov	rax,	~KERNEL_PAGE_mirror
	and	rax,	rdi
	shr	rax,	STATIC_PAGE_SIZE_shift

	; put page back to binary memory map
	mov	rdi,	qword [kernel_environment_base_address]
	mov	rdi,	qword [rdi + KERNEL_STRUCTURE.memory_base_address]
	bts	qword [rdi],	rax

	; restore original registers
	pop	rdi
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - size of memory space in Bytes
;	rsi - pointer of memory space to be shared
;	r11 - pointer to process paging array
; out:
;	CF - set if no enough memory
;	rax - pointer to process shared memory
kernel_memory_share:
	; preserve original registers
	push	rbx
	push	rsi
	push	rdi
	push	r8
	push	r9

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; retrieve pointer to current task descriptor
	call	kernel_task_current

	; reserve space in binary memory map of process
	mov	r9,	qword [r9 + KERNEL_TASK_STRUCTURE.memory_map]
	call	kernel_memory_acquire
	jc	.end	; no enough memory

	; convert page number to logical address
	shl	rdi,	STATIC_PAGE_SIZE_shift

	; map source space to process paging array
	mov	rax,	rdi
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_shared
	sub	rsi,	qword [kernel_page_mirror]
	call	kernel_page_map

.end:
	; restore original registers
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rbx

	; return from routine
	ret