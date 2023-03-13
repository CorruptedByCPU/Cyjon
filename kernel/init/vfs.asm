;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	r8 - pointer to kernel environment variables/routines
kernel_vfs_init:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi
	push	rbp

	;-----------------------------------------------------------------------
	; which storage device contains home folder?
	;-----------------------------------------------------------------------

	; limit of devices
	mov	rcx,	KERNEL_STORAGE_limit

	; devices list base address
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.storage_base_address]

.storage:
	; no more devices?
	dec	rcx
	js	.create	; prepare empty vfs

	; device exist?
	cmp	byte [rax + KERNEL_STORAGE_STRUCTURE.device_type],	EMPTY
	jne	.files	; yes

	; next slot
	add	rax,	KERNEL_STORAGE_STRUCTURE.SIZE

	; next storage
	jmp	.storage

.files:
	; preserve original register
	push	rax
	push	rcx

	; local structure of file descriptor
	sub	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE
	mov	rbp,	rsp	; pointer of file descriptor

	; change storage pointer to ID
	sub	rax,	qword [r8 + KERNEL_STRUCTURE.storage_base_address]
	shr	rax,	KERNEL_STORAGE_STRUCTURE_SIZE_shift

	; search for "welcome.txt" file on storage device
	mov	ecx,	kernel_vfs_file_welcome_end - kernel_vfs_file_welcome
	mov	rsi,	kernel_vfs_file_welcome
	call	kernel_storage_file

	; home storage located?
	cmp	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY
	jne	.init	; yes

	; restore original register
	pop	rcx
	pop	rax

	; not a home storage, check next one
	jmp	.storage

.init:
	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; restore original register
	pop	rcx
	pop	rax

	; preserve home storage id
	shr	rax,	KERNEL_STORAGE_STRUCTURE_SIZE_shift
	mov	qword [r8 + KERNEL_STRUCTURE.storage_home_id],	rax

	; initialize VFS storage
	call	lib_vfs_init

.end:
	; restore original registers
	pop	rbp
	pop	rsi
	pop	rbx
	pop	rax

	; return from routine
	ret

.create:
	; home vfs initialized ready
	jmp	.end