;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_gdt:
	; preserve original registers
	push	rcx
	push	rdi

	; prepare area for Global Descriptor Table
	mov	ecx,	TRUE
	call	kernel_memory_alloc
	mov	qword [r8 + KERNEL.gdt_header + KERNEL_STRUCTURE_GDT_HEADER.base_address],	rdi

	; create code descriptor ring0 (CS)
	mov	qword [rdi + KERNEL_STRUCTURE_GDT.cs_ring0 + KERNEL_STRUCTURE_GDT_ENTRY.access],	KERNEL_GDT_FIELD_ACCESS_read_or_write | KERNEL_GDT_FIELD_ACCESS_executable | KERNEL_GDT_FIELD_ACCESS_code_or_data | KERNEL_GDT_FIELD_ACCESS_present
	mov	qword [rdi + KERNEL_STRUCTURE_GDT.cs_ring0 + KERNEL_STRUCTURE_GDT_ENTRY.flags_and_limit_high],	KERNEL_GDT_FIELD_FLAGS_long_mode << STD_MOVE_BYTE_half;

	; create data descriptor ring0 (SS)
	mov	qword [rdi + KERNEL_STRUCTURE_GDT.ss_ring0 + KERNEL_STRUCTURE_GDT_ENTRY.access],	KERNEL_GDT_FIELD_ACCESS_read_or_write | KERNEL_GDT_FIELD_ACCESS_code_or_data | KERNEL_GDT_FIELD_ACCESS_present;
	mov	qword [rdi + KERNEL_STRUCTURE_GDT.ss_ring0 + KERNEL_STRUCTURE_GDT_ENTRY.flags_and_limit_high],	KERNEL_GDT_FIELD_FLAGS_long_mode << STD_MOVE_BYTE_half;

	;  create data descriptor ring3 (SS)
	mov	qword [rdi + KERNEL_STRUCTURE_GDT.ss_ring3 + KERNEL_STRUCTURE_GDT_ENTRY.access],	KERNEL_GDT_FIELD_ACCESS_read_or_write | KERNEL_GDT_FIELD_ACCESS_code_or_data | KERNEL_GDT_FIELD_ACCESS_level_3 | KERNEL_GDT_FIELD_ACCESS_present;
	mov	qword [rdi + KERNEL_STRUCTURE_GDT.ss_ring3 + KERNEL_STRUCTURE_GDT_ENTRY.flags_and_limit_high],	KERNEL_GDT_FIELD_FLAGS_long_mode << STD_MOVE_BYTE_half;

	;  create code descriptor ring3 (CS)
	mov	qword [rdi + KERNEL_STRUCTURE_GDT.cs_ring3 + KERNEL_STRUCTURE_GDT_ENTRY.access],	KERNEL_GDT_FIELD_ACCESS_read_or_write | KERNEL_GDT_FIELD_ACCESS_executable | KERNEL_GDT_FIELD_ACCESS_code_or_data | KERNEL_GDT_FIELD_ACCESS_level_3 | KERNEL_GDT_FIELD_ACCESS_present;
	mov	qword [rdi + KERNEL_STRUCTURE_GDT.cs_ring3 + KERNEL_STRUCTURE_GDT_ENTRY.flags_and_limit_high],	KERNEL_GDT_FIELD_FLAGS_long_mode << STD_MOVE_BYTE_half;

	; configure header of Global Descriptor Table
	mov	word [r8 + KERNEL.gdt_header + KERNEL_STRUCTURE_GDT_HEADER.limit],	STD_PAGE_byte

	; reload Global Descriptor Table
	lgdt	[r8 + KERNEL.gdt_header]

	; set proper descriptors
	call	kernel_init_gdt_reload

	; initialize stack pointer inside TSS table
	mov	rdi,	KERNEL_STACK_pointer
	mov	qword [r8 + KERNEL.tss_table + KERNEL_STRUCTURE_TSS.rsp0],	rdi

	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret

;------------------------------------------------------------------------------
; void
kernel_init_gdt_reload:
	; preserve original register
	push	rax

	; reload code descriptor
	push	KERNEL_STRUCTURE_GDT.cs_ring0
	push	.cs_reload
	retfq

.cs_reload:
	; reset unused selectors
	xor	ax,	ax
	mov	fs,	ax
	mov	gs,	ax

	; reload global selectors of kernel
	mov	ax,	KERNEL_STRUCTURE_GDT.ss_ring0
	mov	ds,	ax	; data
	mov	es,	ax	; extra
	mov	ss,	ax	; stack

	; restore original register
	pop	rax

	; return from routine
	ret