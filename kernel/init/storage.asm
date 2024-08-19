;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_storage:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; allocate area for list of available storages
	mov	ecx,	MACRO_PAGE_ALIGN_UP( KERNEL_STORAGE_limit * KERNEL_STRUCTURE_STORAGE.SIZE ) >> STD_SHIFT_PAGE
	call	kernel_memory_alloc

	; preserve pointer inside KERNEL environment
	mov	qword [r8 + KERNEL.storage_base_address],	rdi

	; register modules of Virtual File System as storages
	mov	rsi,	qword [kernel_limine_module_request + LIMINE_MODULE_REQUEST.response]

	; amount of entries on modules list
	mov	rax,	qword [rsi + LIMINE_MODULE_RESPONSE.module_count]

	; first entry of modules list
	mov	rdx,	qword [rsi + LIMINE_MODULE_RESPONSE.modules]

.next:
	; all modules parsed?
	dec	rax
	js	.end	; yes

	; preserve module number
	push	rax

	; module properties
	mov	rbx,	qword [rdx + rax * STD_SIZE_PTR_byte]

	; module type of VFS?
	mov	rcx,	qword [rbx + LIMINE_FILE.size]
	mov	rsi,	qword [rbx + LIMINE_FILE.address]
	call	kernel_vfs_identify
	jnz	.leave	; no

	; register module as VFS storage
	mov	al,	KERNEL_STORAGE_TYPE_vfs
	call	kernel_storage_register

	; all device slots are used?
	test	rdi,	rdi
	jz	.leave	; ignore device

	; address of VFS main block location
	mov	qword [rdi + KERNEL_STRUCTURE_STORAGE.device_block],	rsi

	; default block size in Bytes
	mov	qword [rdi + KERNEL_STRUCTURE_STORAGE.device_byte],	STD_PAGE_byte

	; length of storage in Blocks
	MACRO_PAGE_ALIGN_UP_REGISTER	rcx
	shr	rcx,	STD_SHIFT_PAGE
	mov	qword [rdi + KERNEL_STRUCTURE_STORAGE.device_length],	rcx

.leave:
	; restore module number
	pop	rax

	; next module
	jmp	.next

.end:
	; restore original registers
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret