;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	rax - logical address to convert
;	r11 - pointer to paging array
; out:
;	rax - logical address of used page
kernel_page_address:
	; preserve original registers
	push	rax
	push	rcx
	push	r11

	; local variable
	mov	rdx,	KERNEL_PAGE_mirror
	push	rdx

	; we do not support PML5, yet
	mov	rdx,	~KERNEL_PAGE_mask
	and	rax,	rdx

	; compute entry number of PML4 array
	xor	edx,	edx	; higher of address part is not involved in calculations
	mov	rcx,	KERNEL_PAGE_PML3_SIZE_byte
	div	rcx

	; retrieve PML3 address
	or	r11,	qword [rsp]	; convert to logical address
	mov	r11,	qword [r11 + rax * STATIC_QWORD_SIZE_byte]
	and	r11,	STATIC_PAGE_mask	; drop flags

	; compute entry number of PML3 array
	mov	rax,	rdx	; restore rest of division
	mov	rcx,	KERNEL_PAGE_PML2_SIZE_byte
	xor	edx,	edx	; higher of address part is not involved in calculations
	div	rcx

	; retrieve PML2 address
	or	r11,	qword [rsp]	; convert to logical address
	mov	r11,	qword [r11 + rax * STATIC_QWORD_SIZE_byte]
	and	r11,	STATIC_PAGE_mask	; drop flags

	; compute entry number of PML2 array
	mov	rax,	rdx	; restore rest of division
	mov	rcx,	KERNEL_PAGE_PML1_SIZE_byte
	xor	edx,	edx	; higher of address part is not involved in calculations
	div	rcx

	; retrieve PML1 address
	or	r11,	qword [rsp]	; convert to logical address
	mov	r11,	qword [r11 + rax * STATIC_QWORD_SIZE_byte]
	and	r11,	STATIC_PAGE_mask	; drop flags

	; compute entry number of PML1 array
	mov	rax,	rdx	; restore rest of division
	mov	rcx,	STATIC_PAGE_SIZE_byte
	xor	edx,	edx	; higher of address part is not involved in calculations
	div	rcx

	; retrieve PML1 address
	or	r11,	qword [rsp]	; convert to logical address
	mov	rdx,	qword [r11 + rax * STATIC_QWORD_SIZE_byte]
	and	rdx,	STATIC_PAGE_mask	; drop flags

	; convert to logical address
	or	rdx,	qword [rsp]

	; remove local variable
	add	rsp,	STATIC_QWORD_SIZE_byte

	; restore original registers
	pop	r11
	pop	rcx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer
; out:
;	rdi - pointer aligned to page (up)
kernel_page_align_up:
	; align page to next address
	add	rdi,	~STATIC_PAGE_mask
	and	rdi,	STATIC_PAGE_mask

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rax - logical target address
;	bx - flags assigned to target space
;	rcx - length of space in Pages
;	r11 - address of target paging array
kernel_page_alloc:
	; preserve original register
	push	rcx
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; prepare default paging structure
	call	kernel_page_prepare

.next:
	; end of PML1 array?
	cmp	r12,	KERNEL_PAGE_ENTRY_count
	jb	.entry	; no

	; extend paging array
	call	kernel_page_extend

.entry:
	; request page for PML1 entry
	call	kernel_memory_alloc_page
	or	di,	bx	; assign flags

	; register inside entry
	mov	qword [r8 + r12 * STATIC_QWORD_SIZE_byte],	rdi

	; next entry from PML1 array
	inc	r12

	; every page connected?
	dec	rcx
	jnz	.next	; no

.end:
	; restore original registers
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - physical/logical address of page
kernel_page_clean:
	; preserve original register
	push	rcx

	; clean whole 1 page
	mov	rcx,	STATIC_PAGE_SIZE_page
	call	.proceed

	; restore original register
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	rcx - EMPTY
.proceed:
	; preserve original registers
	push	rax
	push	rdi

	; clean area
	xor	rax,	rax
	shl	rcx,	STATIC_MULTIPLE_BY_512_shift	; 8 Bytes at a time
	rep	stosq

	; restore original registers
	pop	rdi
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - pages
;	rdi - physical/logical address
kernel_page_clean_few:
	; preserve original register
	push	rcx

	; convert to Bytes and clean up
	call	kernel_page_clean.proceed

	; restore original register
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	bx - flags assigned to every page entry of that address
;	r9 - old pointer to PML2 entry
;	r10 - old pointer to PML3 entry
;	r11 - old pointer to PML4 entry
;	r13 - old number of PML2 entry
;	r14 - old number of PML3 entry
;	r15 - old number of PML4 entry
; out:
;	r8 - new pointer to PML1 entry
;	r9 - new pointer to PML2 entry
;	r10 - new pointer to PML3 entry
;	r11 - new pointer to PML4 entry
;	r12 - new number of PML1 entry
;	r13 - new number of PML2 entry
;	r14 - new number of PML3 entry
;	r15 - new number of PML4 entry
kernel_page_extend:
	; preserve original register
	push	rdi

	; next entry number
	inc	r13

	; end of PML2 array?
	cmp	r13,	KERNEL_PAGE_ENTRY_count
	je	.pml3	; yes

	; PML2 entry exist?
	cmp	qword [r9 + r13 * STATIC_QWORD_SIZE_byte],	EMPTY
	jne	.pml2_entry	; yes

	; assign page for PML2 entry
	call	kernel_memory_alloc_page

	; store PML1 array address inside PML2 entry
	or	di,	bx	; apply flags
	mov	qword [r9 + r13 * STATIC_QWORD_SIZE_byte],	rdi

.pml2_entry:
	; retrieve PML1 array address from PML2 entry
	mov	r8,	KERNEL_PAGE_mirror	; convert to logical address
	or	r8,	qword [r9 + r13 * STATIC_QWORD_SIZE_byte]
	and	r8,	STATIC_PAGE_mask	; drop flags

	; first entry number of PML1 array
	xor	r12,	r12

	; finished
	jmp	.end

.pml3:
	; next entry number
	inc	r14

	; end of PML3 array?
	cmp	r14,	KERNEL_PAGE_ENTRY_count
	je	.pml4	; yes

	; PML3 entry exist?
	cmp	qword [r10 + r14 * STATIC_QWORD_SIZE_byte],	EMPTY
	jne	.pml3_entry	; yes

	; assign page for PML3 entry
	call	kernel_memory_alloc_page

	; store PML2 array address inside PML3 entry
	or	di,	bx	; apply flags
	mov	qword [r10 + r14 * STATIC_QWORD_SIZE_byte],	rdi

.pml3_entry:
	; retrieve PML2 array address from PML3 entry
	mov	r9,	KERNEL_PAGE_mirror	; convert to logical address
	or	r9,	qword [r10 + r14 * STATIC_QWORD_SIZE_byte]
	and	r9,	STATIC_PAGE_mask	; drop flags

	; first entry number of PML1 array
	xor	r13,	r13

	; new PML2 assigned
	jmp	.pml2_entry

.pml4:
	; next entry number
	inc	r15

	; end of PML4 array?
	cmp	r15,	KERNEL_PAGE_ENTRY_count
	je	.error	; yes

	; PML4 entry exist?
	cmp	qword [r11 + r15 * STATIC_QWORD_SIZE_byte],	EMPTY
	jne	.pml4_entry	; yes

	; assign page for PML4 entry
	call	kernel_memory_alloc_page

	; store PML3 array address inside PML4 entry
	or	di,	bx	; apply flags
	mov	qword [r11 + r15 * STATIC_QWORD_SIZE_byte],	rdi

.pml4_entry:
	; retrieve PML3 array address from PML4 entry
	mov	r10,	KERNEL_PAGE_mirror	; convert to logical address
	or	r10,	qword [r11 + r15 * STATIC_QWORD_SIZE_byte]
	and	r10,	STATIC_PAGE_mask	; drop flags

	; first entry number of PML1 array
	xor	r14,	r14

	; new PML3 assigned
	jmp	.pml3_entry

.end:
	; restore original register
	pop	rdi

	; return from routine
	ret

.error:
	; this is critical behavior, it should never occur
	; you are a bad programmer...
	mov	rsi,	kernel_log_page
	call	driver_serial_string

	; hold the door
	jmp	$

;-------------------------------------------------------------------------------
; in:
;	rax - logical target address
;	bx - flags assigned to target space
;	rcx - length of space in Pages
;	rsi - physical source address
;	r11 - address of target paging array
kernel_page_map:
	; preserve original register
	push	rcx
	push	rsi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; prepare default paging structure
	call	kernel_page_prepare

	; assign flags to source address
	or	si,	bx

.next:
	; end of PML1 array?
	cmp	r12,	KERNEL_PAGE_ENTRY_count
	jb	.entry	; no

	; extend paging array
	call	kernel_page_extend

.entry:
	; store physical source address with corresponding flags
	mov	qword [r8 + r12 * STATIC_QWORD_SIZE_byte],	rsi

	; next part of space
	add	rsi,	STATIC_PAGE_SIZE_byte

	; next entry from PML1 array
	inc	r12

	; every page connected?
	dec	rcx
	jnz	.next	; no

.end:
	; restore original registers
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rsi
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rax - physical(or mirrored) address of considered space
;	bx - flags assigned to every page entry of that address
;	r11 - logical address of target paging array
; out:
;	CF - if there is no enough available pages
;
;	r8 - pointer to PML1 entry
;	r9 - pointer to PML2 entry
;	r10 - pointer to PML3 entry
;	r11 - pointer to PML4 entry
;	r12 - number of PML1 entry
;	r13 - number of PML2 entry
;	r14 - number of PML3 entry
;	r15 - number of PML4 entry
kernel_page_prepare:
	; preserve original register
	push	rax
	push	rcx
	push	rdx
	push	rdi

	; local variable
	mov	rdx,	KERNEL_PAGE_mirror
	push	rdx

	; we do not support PML5, yet
	mov	rdx,	~KERNEL_PAGE_mask
	and	rax,	rdx

	; compute entry number of PML4 array
	xor	edx,	edx	; higher of address part is not involved in calculations
	mov	rcx,	KERNEL_PAGE_PML3_SIZE_byte
	div	rcx

	; store PML4 entry number
	mov	r15,	rax

	; R11[ R15 ] entry exist?
	or	r11,	qword [rsp]	; convert to logical address
	cmp	qword [r11 + rax * STATIC_QWORD_SIZE_byte],	EMPTY
	jne	.pml3	; yes

	; assign page for R15 entry
	call	kernel_memory_alloc_page
	jc	.end

	; store PML3 array address inside PML4 entry
	mov	qword [r11 + rax * STATIC_QWORD_SIZE_byte],	rdi
	or	word [r11 + rax * STATIC_QWORD_SIZE_byte],	bx	; apply flags

.pml3:
	; retrieve PML3 array address from PML4 entry
	mov	r10,	qword [r11 + rax * STATIC_QWORD_SIZE_byte]
	and	r10,	STATIC_PAGE_mask	; drop flags

	; compute entry number of PML3 array
	mov	rax,	rdx	; restore rest of division
	mov	rcx,	KERNEL_PAGE_PML2_SIZE_byte
	xor	edx,	edx	; higher of address part is not involved in calculations
	div	rcx

	; store PML3 entry number
	mov	r14,	rax

	; R10[ R14 ] entry exist?
	or	r10,	qword [rsp]	; convert to logical address
	cmp	qword [r10 + rax * STATIC_QWORD_SIZE_byte],	EMPTY
	jne	.pml2	; yes

	; assign page for R14 entry
	call	kernel_memory_alloc_page
	jc	.end

	; store PML2 array address inside PML3 entry
	mov	qword [r10 + rax * STATIC_QWORD_SIZE_byte],	rdi
	or	word [r10 + rax * STATIC_QWORD_SIZE_byte],	bx	; apply flags

.pml2:
	; retrieve PML2 array address from PML3 entry
	mov	r9,	qword [r10 + rax * STATIC_QWORD_SIZE_byte]
	and	r9,	STATIC_PAGE_mask	; drop flags

	; compute entry number of PML2 array
	mov	rax,	rdx	; restore rest of division
	mov	rcx,	KERNEL_PAGE_PML1_SIZE_byte
	xor	edx,	edx	; higher of address part is not involved in calculations
	div	rcx

	; store PML2 entry number
	mov	r13,	rax

	; R9[ R13 ] entry exist?
	or	r9,	qword [rsp]	; convert to logical address
	cmp	qword [r9 + rax * STATIC_QWORD_SIZE_byte],	EMPTY
	jne	.pml1	; yes

	; assign page for R13 entry
	call	kernel_memory_alloc_page
	jc	.end

	; store PML1 array address inside PML2 entry
	mov	qword [r9 + rax * STATIC_QWORD_SIZE_byte],	rdi
	or	word [r9 + rax * STATIC_QWORD_SIZE_byte],	bx	; apply flags

.pml1:
	; retrieve PML1 array address from PML2 entry
	mov	r8,	KERNEL_PAGE_mirror	; convert to logical address
	or	r8,	qword [r9 + rax * STATIC_QWORD_SIZE_byte]
	and	r8,	STATIC_PAGE_mask	; drop flags

	; compute entry number of PML1 array
	mov	rax,	rdx	; restore rest of division
	mov	rcx,	STATIC_PAGE_SIZE_byte
	xor	edx,	edx	; higher of address part is not involved in calculations
	div	rcx

	; store PML1 entry number
	mov	r12,	rax

.end:
	; remove local variable
	add	rsp,	STATIC_QWORD_SIZE_byte

	; restore original register
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; return from routine
	ret