;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_gdt:
	; preserve original registers
	push	rax
	push	rcx
	push	rdi

	; assign space for GDT and store it
	mov	ecx,	STATIC_PAGE_SIZE_page
	call	kernel_memory_alloc
	mov	qword [kernel_gdt_header + KERNEL_GDT_STRUCTURE_HEADER.address],	rdi

	; create code descriptor of ring0 (CS)
	mov	rax,	0000000000100000100110000000000000000000000000000000000000000000b
	mov	qword [rdi + KERNEL_GDT_STRUCTURE.cs_ring0],	rax	; zapisz

	; create data descriptor of ring0 (DS/SS)
	mov	rax,	0000000000100000100100100000000000000000000000000000000000000000b
	mov	qword [rdi + KERNEL_GDT_STRUCTURE.ds_ring0],	rax	; zapisz

	;  create code descriptor of ring3 (CS)
	mov	rax,	0000000000100000111110000000000000000000000000000000000000000000b
	mov	qword [rdi + KERNEL_GDT_STRUCTURE.cs_ring3],	rax	; zapisz

	;  create data descriptor of ring3 (DS/SS)
	mov	rax,	0000000000100000111100100000000000000000000000000000000000000000b
	mov	qword [rdi + KERNEL_GDT_STRUCTURE.ds_ring3],	rax	; zapisz

	; reload Global Descriptor Table
	lgdt	[kernel_gdt_header]

	; restore original registers
	pop	rdi
	pop	rcx
	pop	rax

	; return from routine
	ret

kernel_init_gdt_reload:
	; preserve original register
	push	rax

	; reload code descriptor
	push	KERNEL_GDT_STRUCTURE.cs_ring0
	push	.cs_reload
	retfq

.cs_reload:
	; reset unused selectors
	xor	ax,	ax
	mov	fs,	ax
	mov	gs,	ax

	; reload global selectors of kernel
	mov	ax,	KERNEL_GDT_STRUCTURE.ds_ring0
	mov	ds,	ax	; data
	mov	es,	ax	; extra
	mov	ss,	ax	; stack

	; restore original register
	pop	rax

	; return from routine
	ret