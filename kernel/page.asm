;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	rsi - logical address of page
;	r11 - pointer to paging array
; out:
;	rax - physical address of page
kernel_page_address:
	; preserve original registers
	push	rdx
	push	r11

	; localize and retrieve page
	call	kernel_page_address.traverse

	; return physical address of page
	mov	rax,	rdx

	; restore original registers
	pop	r11
	pop	rdx

	; return from routine
	ret

.traverse:
	; preserve original registers
	push	rcx

	; we do not support PML5, yet
	mov	rax,	rsi
	mov	rdx,	~KERNEL_PAGE_mask
	and	rax,	rdx

	; compute entry number of PML4 array
	xor	edx,	edx	; higher of address part is not involved in calculations
	mov	rcx,	KERNEL_PAGE_PML3_SIZE_byte
	div	rcx

	; retrieve PML3 address
	or	r11,	qword [kernel_page_mirror]	; convert to logical address
	mov	r11,	qword [r11 + rax * STATIC_QWORD_SIZE_byte]
	and	r11,	STATIC_PAGE_mask	; drop flags

	; compute entry number of PML3 array
	mov	rax,	rdx	; restore rest of division
	mov	rcx,	KERNEL_PAGE_PML2_SIZE_byte
	xor	edx,	edx	; higher of address part is not involved in calculations
	div	rcx

	; retrieve PML2 address
	or	r11,	qword [kernel_page_mirror]	; convert to logical address
	mov	r11,	qword [r11 + rax * STATIC_QWORD_SIZE_byte]
	and	r11,	STATIC_PAGE_mask	; drop flags

	; compute entry number of PML2 array
	mov	rax,	rdx	; restore rest of division
	mov	rcx,	KERNEL_PAGE_PML1_SIZE_byte
	xor	edx,	edx	; higher of address part is not involved in calculations
	div	rcx

	; retrieve PML1 address
	or	r11,	qword [kernel_page_mirror]	; convert to logical address
	mov	r11,	qword [r11 + rax * STATIC_QWORD_SIZE_byte]
	and	r11,	STATIC_PAGE_mask	; drop flags

	; compute entry number of PML1 array
	mov	rax,	rdx	; restore rest of division
	mov	rcx,	STATIC_PAGE_SIZE_byte
	xor	edx,	edx	; higher of address part is not involved in calculations
	div	rcx

	; retrieve PML1 address
	or	r11,	qword [kernel_page_mirror]	; convert to logical address
	mov	rdx,	qword [r11 + rax * STATIC_QWORD_SIZE_byte]
	and	rdx,	STATIC_PAGE_mask	; drop flags

	; restore original registers
	pop	rcx

	; return from subroutine
	ret

;-------------------------------------------------------------------------------
; in:
;	rax - logical target address
;	bx - flags assigned to target space
;	rcx - length of space in Pages
;	r11 - address of target paging array
; out:
;	CF - if there is no enough available pages
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
	jc	.end	; no enough memory

.next:
	; end of PML1 array?
	cmp	r12,	KERNEL_PAGE_ENTRY_count
	jb	.entry	; no

	; extend paging array
	call	kernel_page_resolve
	jc	.end	; no enough memory

.entry:
	; request page for PML1 entry
	call	kernel_memory_alloc_page
	jc	.end	; no enough memory

	; assign flags
	or	di,	bx

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
;	rax - logical target address
;	bx - flags assigned to target space
;	rcx - length of space in Pages
;	rsi - logical source address
;	r11 - address of target paging array
; out:
;	CF - if there is no enough available pages
kernel_page_clang:
	; preserve original register
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; retrieve parents paging array pointer
	call	kernel_task_active
	mov	rdx,	qword [r9 + KERNEL_TASK_STRUCTURE.cr3]

	; prepare default paging structure
	call	kernel_page_prepare
	jc	.end	; no enough memory

.next:
	; end of PML1 array?
	cmp	r12,	KERNEL_PAGE_ENTRY_count
	jb	.entry	; no

	; extend paging array
	call	kernel_page_resolve
	jc	.end	; no enough memory

.entry:
	; preserve original register
	push	r11

	; resolve physical address from parent paging array
	mov	r11,	rdx
	call	kernel_page_address

	; restore original register
	pop	r11

	; store physical source address with corresponding flags
	or	ax,	bx	; apply flags
	mov	qword [r8 + r12 * STATIC_QWORD_SIZE_byte],	rax

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
	pop	rdx
	pop	rcx
	pop	rax

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
;	rdi - pointer to paging array
kernel_page_deconstruction:
	; preserve original registers
	push	rcx
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11

	; convert process paging array pointer to high half
	mov	r11,	rdi
	or	r11,	qword [kernel_page_mirror]

	; first kernel entry in PML4 array
	xor	ecx,	ecx

.pml4:
	; kernel entry is empty?
	cmp	qword [r11 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	je	.pml4_next	; yes

	; preserve original register
	push	rcx

	; kernel PML3 array
	mov	r10,	qword [r11 + rcx * STATIC_PTR_SIZE_byte]
	or	r10,	qword [kernel_page_mirror]
	and	r10,	STATIC_PAGE_mask

	; first kernel entry of PML3 array
	xor	ecx,	ecx

.pml3:
	; kernel entry is empty?
	cmp	qword [r10 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	je	.pml3_next	; yes

	; preserve original register
	push	rcx

	; kernel PML2 array
	mov	r9,	qword [r10 + rcx * STATIC_PTR_SIZE_byte]
	or	r9,	qword [kernel_page_mirror]
	and	r9,	STATIC_PAGE_mask

	; first kernel entry of PML2 array
	xor	ecx,	ecx

.pml2:
	; kernel entry is empty?
	cmp	qword [r9 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	je	.pml2_next	; yes

	; preserve original register
	push	rcx

	; kernel PML1 array
	mov	r8,	qword [r9 + rcx * STATIC_PTR_SIZE_byte]
	or	r8,	qword [kernel_page_mirror]
	and	r8,	STATIC_PAGE_mask

	; first kernel entry of PML1 array
	xor	ecx,	ecx

.pml1:
	; kernel entry is empty?
	cmp	qword [r8 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	je	.pml1_next	; yes

	; page belongs to process?
	test	word [r8 + rcx * STATIC_PTR_SIZE_byte],	KERNEL_PAGE_FLAG_process
	jz	.pml1_next	; no

	; release page from array
	mov	rdi,	qword [r8 + rcx * STATIC_PTR_SIZE_byte]
	and	di,	STATIC_PAGE_mask	; drop flags
	or	rdi,	qword [kernel_page_mirror]	; convert page address to logical
	call	kernel_memory_release_page

.pml1_next:
	; next entry
	inc	cx

	; end of PML1 array?
	cmp	cx,	KERNEL_PAGE_ENTRY_count
	jb	.pml1	; no

	; restore original register
	pop	rcx

	; PML1 belongs to process?
	test	word [r9 + rcx * STATIC_PTR_SIZE_byte],	KERNEL_PAGE_FLAG_process
	jz	.pml2_next	; no

	; release PML1 from array
	mov	rdi,	qword [r9 + rcx * STATIC_PTR_SIZE_byte]
	and	di,	STATIC_PAGE_mask	; drop flags
	or	rdi,	qword [kernel_page_mirror]	; convert page address to logical
	call	kernel_memory_release_page

.pml2_next:
	; next entry
	inc	cx

	; end of PML2 array?
	cmp	cx,	KERNEL_PAGE_ENTRY_count
	jb	.pml2	; no

	; restore original register
	pop	rcx

	; PML2 belongs to process?
	test	word [r10 + rcx * STATIC_PTR_SIZE_byte],	KERNEL_PAGE_FLAG_process
	jz	.pml3_next	; no

	; release PML2 from array
	mov	rdi,	qword [r10 + rcx * STATIC_PTR_SIZE_byte]
	and	di,	STATIC_PAGE_mask	; drop flags
	or	rdi,	qword [kernel_page_mirror]	; convert page address to logical
	call	kernel_memory_release_page

.pml3_next:
	; next entry
	inc	cx

	; end of PML3 array?
	cmp	cx,	KERNEL_PAGE_ENTRY_count
	jb	.pml3	; no

	; restore original register
	pop	rcx

	; PML3 belongs to process?
	test	word [r11 + rcx * STATIC_PTR_SIZE_byte],	KERNEL_PAGE_FLAG_process
	jz	.pml4_next	; no

	; release PML3 from array
	mov	rdi,	qword [r11 + rcx * STATIC_PTR_SIZE_byte]
	and	di,	STATIC_PAGE_mask	; drop flags
	or	rdi,	qword [kernel_page_mirror]	; convert page address to logical
	call	kernel_memory_release_page

.pml4_next:
	; next entry
	inc	cx

	; end of PML4 array?
	cmp	cx,	KERNEL_PAGE_ENTRY_count
	jb	.pml4	; no

	; release PML4 array
	mov	rdi,	r11
	and	di,	STATIC_PAGE_mask	; drop flags
	or	rdi,	qword [kernel_page_mirror]	; convert page address to logical
	call	kernel_memory_release_page

	; restore original registers
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
;	rax - logical target address
;	bx - new flags to set
;	rcx - length of space in Pages
;	r11 - address of target paging array
kernel_page_flags:
	; preserve original register
	push	rcx
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; resolve default paging structure
	call	kernel_page_prepare
	jc	.end	; no enough memory

	; assign flags to source address
	or	si,	bx

.next:
	; end of PML1 array?
	cmp	r12,	KERNEL_PAGE_ENTRY_count
	jb	.entry	; no

	; retrieve next PML1 array
	call	kernel_page_resolve

.entry:
	; store physical source address with corresponding flags
	and	word [r8 + r12 * STATIC_QWORD_SIZE_byte],	STATIC_PAGE_mask
	or	word [r8 + r12 * STATIC_QWORD_SIZE_byte],	bx

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
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rax - logical target address
;	bx - flags assigned to target space
;	rcx - length of space in Pages
;	rsi - physical source address
;	r11 - address of target paging array
; out:
;	CF - if there is no enough available pages
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
	jc	.end	; no enough memory

	; assign flags to source address
	or	si,	bx

.next:
	; end of PML1 array?
	cmp	r12,	KERNEL_PAGE_ENTRY_count
	jb	.entry	; no

	; extend paging array
	call	kernel_page_resolve
	jc	.end	; no enough memory

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
;	r11 - physical pointer to process paging array
kernel_page_merge:
	; preserve original registers
	push	rcx
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; convert process paging array pointer to high half
	or	r11,	qword [kernel_page_mirror]

	; first kernel entry in PML4 array
	xor	rcx,	rcx

	; kernel PML4 array
	mov	r15,	qword [kernel_environment_base_address]
	mov	r15,	qword [r15 + KERNEL_STRUCTURE.page_base_address]

.pml4:
	; kernel entry is empty?
	cmp	qword [r15 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	je	.pml4_next	; yes

	; process entry is empty?
	cmp	qword [r11 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	je	.pml4_map	; yes

	; preserve original register
	push	rcx

	; kernel PML3 array
	mov	r14,	qword [r15 + rcx * STATIC_PTR_SIZE_byte]
	and	r14,	STATIC_PAGE_mask	; drop flags
	or	r14,	qword [kernel_page_mirror]	; convert page address to logical
	; process PML3 array
	mov	r10,	qword [r11 + rcx * STATIC_PTR_SIZE_byte]
	and	r10,	STATIC_PAGE_mask	; drop flags
	or	r10,	qword [kernel_page_mirror]	; convert page address to logical

	; first kernel entry of PML3 array
	xor	ecx,	ecx

.pml3:
	; kernel entry is empty?
	cmp	qword [r14 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	je	.pml3_next	; yes

	; process entry is empty?
	cmp	qword [r10 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	je	.pml3_map	; yes

	; preserve original register
	push	rcx

	; kernel PML2 array
	mov	r13,	qword [r14 + rcx * STATIC_PTR_SIZE_byte]
	and	r13,	STATIC_PAGE_mask	; drop flags
	or	r13,	qword [kernel_page_mirror]	; convert page address to logical
	; process PML2 array
	mov	r9,	qword [r10 + rcx * STATIC_PTR_SIZE_byte]
	and	r9,	STATIC_PAGE_mask	; drop flags
	or	r9,	qword [kernel_page_mirror]	; convert page address to logical

	; first kernel entry of PML2 array
	xor	ecx,	ecx

.pml2:
	; kernel entry is empty?
	cmp	qword [r13 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	je	.pml2_next	; yes

	; process entry is empty?
	cmp	qword [r9 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	je	.pml2_map	; yes

	; preserve original register
	push	rcx

	; kernel PML1 array
	mov	r12,	qword [r13 + rcx * STATIC_PTR_SIZE_byte]
	and	r12,	STATIC_PAGE_mask	; drop flags
	or	r12,	qword [kernel_page_mirror]	; convert page address to logical
	; process PML1 array
	mov	r8,	qword [r9 + rcx * STATIC_PTR_SIZE_byte]
	and	r8,	STATIC_PAGE_mask	; drop flags
	or	r8,	qword [kernel_page_mirror]	; convert page address to logical

	; first kernel entry of PML1 array
	xor	ecx,	ecx

.pml1:
	; kernel entry is empty?
	cmp	qword [r12 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	je	.pml1_next	; yes

	; process entry is empty?
	cmp	qword [r8 + rcx * STATIC_PTR_SIZE_byte],	EMPTY
	jne	.pml1_next	; yes

	; map to process
	push	qword [r12 + rcx * STATIC_PTR_SIZE_byte]
	pop	qword [r8 + rcx * STATIC_PTR_SIZE_byte]

.pml1_next:
	; next entry
	inc	cx

	; end of PML1 array?
	cmp	cx,	KERNEL_PAGE_ENTRY_count
	jb	.pml1	; no

	; restore original register
	pop	rcx

	; next entry
	jmp	.pml2_next

.pml2_map:
	; map to process
	push	qword [r13 + rcx * STATIC_PTR_SIZE_byte]
	pop	qword [r9 + rcx * STATIC_PTR_SIZE_byte]

.pml2_next:
	; next entry
	inc	cx

	; end of PML2 array?
	cmp	cx,	KERNEL_PAGE_ENTRY_count
	jb	.pml2	; no

	; restore original register
	pop	rcx

	; next entry
	jmp	.pml3_next

.pml3_map:
	; map to process
	push	qword [r14 + rcx * STATIC_PTR_SIZE_byte]
	pop	qword [r10 + rcx * STATIC_PTR_SIZE_byte]

.pml3_next:
	; next entry
	inc	cx

	; end of PML3 array?
	cmp	cx,	KERNEL_PAGE_ENTRY_count
	jb	.pml3	; no

	; restore original register
	pop	rcx

	; next entry
	jmp	.pml4_next

.pml4_map:
	; map to process
	push	qword [r15 + rcx * STATIC_PTR_SIZE_byte]
	pop	qword [r11 + rcx * STATIC_PTR_SIZE_byte]

.pml4_next:
	; next entry
	inc	cx

	; end of PML4 array?
	cmp	cx,	KERNEL_PAGE_ENTRY_count
	jb	.pml4	; no

	; restore original registers
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
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
	or	r11,	qword [kernel_page_mirror]	; convert to logical address
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
	or	r10,	qword [kernel_page_mirror]	; convert to logical address
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
	or	r9,	qword [kernel_page_mirror]	; convert to logical address
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
	mov	r8,	qword [r9 + rax * STATIC_QWORD_SIZE_byte]
	or	r8,	qword [kernel_page_mirror]	; convert to logical address
	and	r8,	STATIC_PAGE_mask	; drop flags

	; compute entry number of PML1 array
	mov	rax,	rdx	; restore rest of division
	mov	rcx,	STATIC_PAGE_SIZE_byte
	xor	edx,	edx	; higher of address part is not involved in calculations
	div	rcx

	; store PML1 entry number
	mov	r12,	rax

.end:
	; restore original register
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rax - logical target address
;	rcx - length of space in Pages
;	r11 - pointer of paging array
kernel_page_release:
	; preserve original register
	push	rax
	push	rdx
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
	push	rcx

	;-----------------------------------------------------------------------

	; we do not support PML5, yet
	mov	rdx,	~KERNEL_PAGE_mask
	and	rax,	rdx

	; compute entry number of PML4 array
	xor	edx,	edx	; higher of address part is not involved in calculations
	mov	rcx,	KERNEL_PAGE_PML3_SIZE_byte
	div	rcx

	; store PML4 entry number
	mov	r15,	rax

	; convert pointer of PML4 to logical
	or	r11,	qword [kernel_page_mirror]

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

	; convert pointer of PML3 to logical
	or	r10,	qword [kernel_page_mirror]

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

	; convert pointer of PML2 to logical
	or	r9,	qword [kernel_page_mirror]

	; retrieve PML1 array address from PML2 entry
	mov	r8,	qword [r9 + rax * STATIC_QWORD_SIZE_byte]
	and	r8,	STATIC_PAGE_mask	; drop flags

	; compute entry number of PML1 array
	mov	rax,	rdx	; restore rest of division
	mov	rcx,	STATIC_PAGE_SIZE_byte
	xor	edx,	edx	; higher of address part is not involved in calculations
	div	rcx

	; store PML1 entry number
	mov	r12,	rax

	; convert pointer of PML1 to logical
	or	r8,	qword [kernel_page_mirror]

	;-----------------------------------------------------------------------

	; space size in pages
	mov	rcx,	qword [rsp]

.pml1:
	; prepare page for release
	xor	edi,	edi
	xchg	rdi,	qword [r8 + r12 * STATIC_QWORD_SIZE_byte]

	; page exist?
	test	rdi,	rdi
	jz	.no

	; release page
	and	di,	STATIC_PAGE_mask	; drop flags
	or	rdi,	qword [kernel_page_mirror]	; convert page address to logical
	call	kernel_memory_release_page

.no:
	; page from space, released
	dec	rcx	; even if not exist!
	jz	.end	; whole space released

	; next page from area?
	inc	r12

	; end of PML1 array?
	cmp	r12,	KERNEL_PAGE_ENTRY_count
	jb	.pml1	; yes

.pml2:
	; next entry of PML2
	inc	r13

	; end of PML2 array?
	cmp	r13,	KERNEL_PAGE_ENTRY_count
	je	.pml3	; yes

.pml2_continue:
	; PML2 entry is empty?
	cmp	qword [r9 + r13 * STATIC_QWORD_SIZE_byte],	EMPTY
	je	.pml2_empty	; yes

	; retrieve PML1 address
	mov	r8,	qword [r9 + r13 * STATIC_QWORD_SIZE_byte]

	; drop flags and convert to logical address
	and	r8w,	STATIC_PAGE_mask
	or	r8,	qword [kernel_page_mirror]

	; start from first entry
	xor	r12,	r12

	; continue with PML1
	jmp	.pml1

.pml2_empty:
	; forced release
	sub	rcx,	KERNEL_PAGE_ENTRY_count
	jz	.end	; whole space released
	js	.end	; even more than required

	; try next entry from PML2
	jmp	.pml2

.pml3:
	; next entry of PML3
	inc	r14

	; end of PML3 array?
	cmp	r14,	KERNEL_PAGE_ENTRY_count
	je	.pml4	; yes

.pml3_continue:
	; PML3 entry is empty?
	cmp	qword [r10 + r14 * STATIC_QWORD_SIZE_byte],	EMPTY
	je	.pml3_empty	; yes

	; retrieve PML2 address
	mov	r9,	qword [r10 + r14 * STATIC_QWORD_SIZE_byte]

	; drop flags and convert to logical address
	and	r9w,	STATIC_PAGE_mask
	or	r9,	qword [kernel_page_mirror]

	; start from first entry
	xor	r13,	r13

	; continue with PML2
	jmp	.pml2_continue

.pml3_empty:
	; forced release
	sub	rcx,	KERNEL_PAGE_ENTRY_count * KERNEL_PAGE_ENTRY_count
	jz	.end	; whole space released
	js	.end	; even more than required

	; try next entry from PML3
	jmp	.pml3

.pml4:
	; next entry of PML4
	inc	r15

	; end of PML4 array?
	cmp	r15,	KERNEL_PAGE_ENTRY_count
	je	.pml5	; yes

	; PML4 entry is empty?
	cmp	qword [r11 + r15 * STATIC_QWORD_SIZE_byte],	EMPTY
	je	.pml4_empty	; yes

	; retrieve PML3 address
	mov	r10,	qword [r11 + r15 * STATIC_QWORD_SIZE_byte]

	; drop flags and convert to logical address
	and	r10w,	STATIC_PAGE_mask
	or	r10,	qword [kernel_page_mirror]

	; start from first entry
	xor	r14,	r14

	; continue with PML3
	jmp	.pml3_continue

.pml4_empty:
	; forced release
	sub	rcx,	KERNEL_PAGE_ENTRY_count * KERNEL_PAGE_ENTRY_count * KERNEL_PAGE_ENTRY_count
	jz	.end	; whole space released
	js	.end	; even more than required

	; try next entry from PML4
	jmp	.pml4

.pml5:
	; are you insane? :O
	jmp	$

.end:
	; restore original registers
	pop	rcx
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rdx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rsi - logical address of page
;	r11 - pointer to paging array
; out:
;	rax - physical address of page
kernel_page_remove:
	; preserve original registers
	push	rdx
	push	r11

	; localize and retrieve page
	call	kernel_page_address.traverse

	; remove page from pagings
	mov	qword [r11 + rax * STATIC_QWORD_SIZE_byte],	EMPTY

	; return physical address of page
	mov	rax,	rdx

	; restore original registers
	pop	r11
	pop	rdx

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
;	CF - if there is no enough available pages
;
;	r8 - new pointer to PML1 entry
;	r9 - new pointer to PML2 entry
;	r10 - new pointer to PML3 entry
;	r11 - new pointer to PML4 entry
;	r12 - new number of PML1 entry
;	r13 - new number of PML2 entry
;	r14 - new number of PML3 entry
;	r15 - new number of PML4 entry
kernel_page_resolve:
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
	jc	.end	; no enough memory

	; store PML1 array address inside PML2 entry
	or	di,	bx	; apply flags
	mov	qword [r9 + r13 * STATIC_QWORD_SIZE_byte],	rdi

.pml2_entry:
	; retrieve PML1 array address from PML2 entry
	mov	r8,	qword [r9 + r13 * STATIC_QWORD_SIZE_byte]
	or	r8,	qword [kernel_page_mirror]	; convert page address to logical
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
	jc	.end	; no enough memory

	; store PML2 array address inside PML3 entry
	or	di,	bx	; apply flags
	mov	qword [r10 + r14 * STATIC_QWORD_SIZE_byte],	rdi

.pml3_entry:
	; retrieve PML2 array address from PML3 entry
	mov	r9,	qword [r10 + r14 * STATIC_QWORD_SIZE_byte]
	or	r9,	qword [kernel_page_mirror]	; convert page address to logical
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
	jc	.end	; no enough memory

	; store PML3 array address inside PML4 entry
	or	di,	bx	; apply flags
	mov	qword [r11 + r15 * STATIC_QWORD_SIZE_byte],	rdi

.pml4_entry:
	; retrieve PML3 array address from PML4 entry
	mov	r10,	qword [r11 + r15 * STATIC_QWORD_SIZE_byte]
	or	r10,	qword [kernel_page_mirror]	; convert page address to logical
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