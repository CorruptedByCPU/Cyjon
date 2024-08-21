;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

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
	push	rbx
	push	r8
	push	rcx

	; global kernel environment variables/functions/rountines
	mov	r8,	qword [kernel]

	; define memory semaphore location
	mov	rbx,	qword [r8 + KERNEL.page_limit]
	shr	rbx,	STD_SHIFT_8
	inc	rbx
	MACRO_PAGE_ALIGN_UP_REGISTER	rbx
	dec	rbx

	; block access to binary memory map (only one process at a time)
	MACRO_LOCK	r9,	rbx

	; start from first page of binary memory map
	xor	eax,	eax

.new:
	; start of new considered space
	mov	rdi,	rax

	; length of considered space
	xor	ecx,	ecx

.check:
	; check
	bt	qword [r9],	rax

	; next page from area and its current length
	inc	rax
	inc	rcx

	; continuity ensured?
	jnc	.new	; no

	; area located?
	cmp	rcx,	qword [rsp]
	je	.found	; yes

	; end of binary memory map?
	cmp	rax,	qword [r8 + KERNEL.page_limit]
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
	jnz	.mark	; yes

	; allocation successful
	clc

	; end of routine
	jmp	.end

.error:
	; operation failed
	stc

.end:
	; release access
	MACRO_UNLOCK	r9,	rbx

	; restore original registers
	pop	rcx
	pop	r8
	pop	rbx
	pop	rax

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
	push	r8
	push	r9

	; global kernel environment variables/functions/rountines
	mov	r8,	qword [kernel]

	; search for requested length of area
	mov	r9,	qword [r8 + KERNEL.memory_base_address]
	call	kernel_memory_acquire
	jc	.end	; no enough memory

	; less memory available
	sub	qword [r8 + KERNEL.page_available],	rcx

	; convert page number to its logical address
	shl	rdi,	STD_SHIFT_PAGE
	add	rdi,	qword [kernel_page_mirror]

	; we guarantee clean memory area at first use
	call	kernel_memory_clean

.end:
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
	mov	ecx,	STD_PAGE_page
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
;	rcx - amount of pages to cleanup
;	rdi - physical/logical address of page
kernel_memory_clean:
	; preserve original registers
	push	rax
	push	rcx
	push	rdi

	; clear area
	xor	eax,	eax
	shl	rcx,	STD_SHIFT_512	; 8 Bytes at a time
	rep	stosq

	; restore original registers
	pop	rdi
	pop	rcx
	pop	rax

	; return from routine
	ret

;------------------------------------------------------------------------------
; in:
;	rcx - amount of pages to release
;	rdi - first page number
;	r9 - pointer to binary memory map
kernel_memory_dispose:
	; preserve original registers
	push	rcx
	push	rdi

.loop:
	; all pages released?
	dec	rcx
	js	.end	; yes

	; release page
	bts	qword [r9],	rdi

	; next page
	inc	rdi

	; continue
	jmp	.loop

.end:
	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - area length in Pages
;	rdi - logical pointer to area
kernel_memory_release:
	; preserve original registers
	push	r9
	push	rdi

	; global kernel environment variables/functions/rountines
	mov	r9,	qword [kernel]

	; release occupied pages inside kernels binary memory map
	mov	rdi,	~KERNEL_PAGE_mirror
	and	rdi,	qword [rsp]
	shr	rdi,	STD_SHIFT_PAGE
	mov	r9,	qword [r9 + KERNEL.memory_base_address]
	call	kernel_memory_dispose

	; global kernel environment variables/functions/rountines
	mov	r9,	qword [kernel]
	add	qword [r9 + KERNEL.page_available],	rcx	; more available pages

	; restore original registers
	pop	rdi
	pop	r9

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - logical page address
kernel_memory_release_page:
	; preserve original registers
	push	rcx
	push	rdi

	; release page
	mov	rcx,	STD_PAGE_page
	or	rdi,	qword [kernel_page_mirror]
	call	kernel_memory_release

	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret