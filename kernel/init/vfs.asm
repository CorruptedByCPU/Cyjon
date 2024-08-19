;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_vfs:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; allocate area for list of open files
	mov	ecx,	MACRO_PAGE_ALIGN_UP( KERNEL_VFS_limit * KERNEL_STRUCTURE_VFS.SIZE ) >> STD_SHIFT_PAGE
	call	kernel_memory_alloc

	; preserve pointer inside KERNEL environment
	mov	qword [r8 + KERNEL.vfs_base_address],	rdi

	; detect VFS storages

	; list length in entries
	mov	rcx,	KERNEL_STORAGE_limit

	; first entry of devices list
	mov	rax,	qword [r8 + KERNEL.storage_base_address]

.storage:
	; no more devices?
	dec	rcx
	js	.end	; done

	; entry marked as VFS?
	cmp	byte [rax + KERNEL_STRUCTURE_STORAGE.device_type],	KERNEL_STORAGE_TYPE_vfs
	je	.vfs	; yes

.next:
	; next slot
	add	rax,	KERNEL_STRUCTURE_STORAGE.SIZE

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
	push	qword [rax + KERNEL_STRUCTURE_STORAGE.device_block]
	pop	qword [rdi + LIB_VFS_STRUCTURE.offset]

	xchg	bx,bx

	; realloc VFS structure regarded of memory location
	mov	rsi,	rdi
	call	kernel_init_vfs_realloc
	mov	qword [rdi + LIB_VFS_STRUCTURE.byte],	rcx

	; set new location of VFS main block
	mov	qword [rax + KERNEL_STRUCTURE_STORAGE.device_block],	rdi

	; next storage
	jmp	.next

.end:
	; restore original register
	pop	rdi
	pop	rsi
	pop	rcx
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