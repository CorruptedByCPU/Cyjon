;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

kernel_init_vfs_path	db	"/system/etc/version"
kernel_init_vfs_path_end:

;-------------------------------------------------------------------------------
; void
kernel_init_vfs:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi
	push	r9

	; retrieve pointer to currently running task (kernel)
	call	kernel_task_active

	; allocate area for list of open files
	mov	ecx,	MACRO_PAGE_ALIGN_UP( KERNEL_VFS_limit * KERNEL_STRUCTURE_VFS.SIZE ) >> STD_SHIFT_PAGE
	call	kernel_memory_alloc

	; preserve pointer inside KERNEL environment
	mov	qword [r8 + KERNEL.vfs_base_address],	rdi

	; detect VFS storages

	; first entry of devices list
	xor	eax,	eax
	mov	rbx,	qword [r8 + KERNEL.storage_base_address]

.storage:
	; no more devices?
	cmp	rax,	KERNEL_STORAGE_limit
	jnb	.end	; done

	; entry marked as VFS?
	cmp	byte [rbx + KERNEL_STRUCTURE_STORAGE.device_type],	KERNEL_STORAGE_TYPE_vfs
	je	.vfs	; yes

.next:
	; next slot
	inc	rax
	add	rbx,	KERNEL_STRUCTURE_STORAGE.SIZE

	; next storage
	jmp	.storage

.vfs:
	; create superblock for VFS
	mov	ecx,	MACRO_PAGE_ALIGN_UP( LIB_VFS_block ) >> STD_SHIFT_PAGE
	call	kernel_memory_alloc

	; superblock is of type: directory
	mov	byte [rdi + LIB_VFS_STRUCTURE.type],		STD_FILE_TYPE_directory

	; root directory name
	mov	byte [rdi + LIB_VFS_STRUCTURE.name_length],	INIT
	mov	byte [rdi + LIB_VFS_STRUCTURE.name],		STD_ASCII_SLASH

	; superblock content offset
	push	qword [rbx + KERNEL_STRUCTURE_STORAGE.device_block]
	pop	qword [rdi + LIB_VFS_STRUCTURE.offset]

	; realloc VFS structure regarded of memory location
	mov	rsi,	rdi
	call	kernel_init_vfs_realloc
	MACRO_PAGE_ALIGN_UP_REGISTER	rcx
	mov	qword [rdi + LIB_VFS_STRUCTURE.byte],	rcx

	; set new location of VFS main block
	mov	qword [rbx + KERNEL_STRUCTURE_STORAGE.device_block],	rdi

	; kernels current directory already assigned?
	cmp	qword [r9 + KERNEL_STRUCTURE_TASK.directory],	EMPTY
	jne	.next	; yes

	; set this one as default storage
	mov	qword [r8 + KERNEL.storage_root],	rax

	; preserve original register
	push	rdi

	; retrieve properties of file
	mov	ecx,	kernel_init_vfs_path_end - kernel_init_vfs_path
	mov	rsi,	kernel_init_vfs_path
	call	kernel_vfs_path

	; file found?
	test	rdi,	rdi

	; restore original register
	pop	rdi

	; if no
	jz	.next

	; kernels current directory
	mov	qword [r9 + KERNEL_STRUCTURE_TASK.directory],	rdi

	; next storage
	jmp	.next

.end:
	; restore original register
	pop	r9
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret

;------------------------------------------------------------------------------
; in:
;	rsi - current directory pointer
;	rdi - previous directory pointer
; out:
;	rcx - new length of current directory in Bytes
kernel_init_vfs_realloc:
	; preserve original registers
	push	rax
	push	rdx
	push	rsi
	push	rdi

	; size of this directory
	xor	ecx,	ecx

	; file properties
	mov	rax,	qword [rsi + LIB_VFS_STRUCTURE.offset]

	; for every file

.file:
	; default file content address
	mov	rdx,	qword [rsi + LIB_VFS_STRUCTURE.offset]
	add	qword [rax + LIB_VFS_STRUCTURE.offset],	rdx

	; modify offset depending on file type

	; for default symbolic links
	cmp	byte [rax + LIB_VFS_STRUCTURE.type],	STD_FILE_TYPE_link
	jne	.no_symbolic_link

	; current?
	cmp	byte [rax + LIB_VFS_STRUCTURE.name_length],	1
	jne	.no_current	; no
	cmp	byte [rax + LIB_VFS_STRUCTURE.name],		STD_ASCII_DOT
	jne	.no_current	; also not

	; yes
	mov	qword [rax + LIB_VFS_STRUCTURE.offset],	rsi

	; next file
	jmp	.next

.no_current:
	; previous?
	cmp	byte [rax + LIB_VFS_STRUCTURE.name_length],	2
	jne	.no_symbolic_link	; no
	cmp	word [rax + LIB_VFS_STRUCTURE.name],		(STD_ASCII_DOT << STD_MOVE_BYTE) | STD_ASCII_DOT
	jne	.no_symbolic_link	; also not

	; yes
	mov	qword [rax + LIB_VFS_STRUCTURE.offset],	rdi

	; next file
	jmp	.next

.no_symbolic_link:
	; for directories
	cmp	byte [rax + LIB_VFS_STRUCTURE.type],	STD_FILE_TYPE_directory
	jne	.next	; no

	; preserve original registers
	push	rcx
	push	rsi
	push	rdi

	; parse directory entries
	mov	rdi,	rsi
	mov	rsi,	rax
	call	kernel_init_vfs_realloc

	; update directory content size in Bytes
	MACRO_PAGE_ALIGN_UP_REGISTER	rcx
	mov	qword [rax + LIB_VFS_STRUCTURE.byte],	rcx

	; restore original registers
	pop	rdi
	pop	rsi
	pop	rcx

.next:
	; entry parsed
	add	rcx,	LIB_VFS_STRUCTURE.SIZE

	; move pointer to next file
	add	rax,	LIB_VFS_STRUCTURE.SIZE

	; no more files?
	cmp	byte [rax + LIB_VFS_STRUCTURE.name_length],	EMPTY
	jne	.file	; yes, parse it

	; restore original registers
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; return from routine
	ret