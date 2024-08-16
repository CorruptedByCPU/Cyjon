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
	push	r9
	push	r11

	; modules available?
	cmp	qword [kernel_limine_module_request + LIMINE_MODULE_REQUEST.response],	EMPTY
	je	.error	; no

	; kernel task properties
	call	kernel_task_active

	; assign space for storage list
	mov	ecx,	((KERNEL_STORAGE_limit * KERNEL_STORAGE_STRUCTURE.SIZE) + ~STD_PAGE_mask) >> STD_SHIFT_PAGE
	call	kernel_memory_alloc

	; save pointer to storage list
	mov	qword [r8 + KERNEL.storage_base_address],	rdi

	; pointer of modules response structure
	mov	rbx,	qword [kernel_limine_module_request + LIMINE_MODULE_REQUEST.response]

	; first entry of modules list
	xor	eax,	eax
	mov	rdx,	qword [rbx + LIMINE_MODULE_RESPONSE.modules]

.next:
	; retrieve entry address
	mov	r11,	qword [rdx + rax * STD_SIZE_PTR_byte]

	;-----------------------------------------------------------------------
	; VFS module?
	;----------------------------------------------------------------------

	; properties of module
	mov	rcx,	qword [r11 + LIMINE_FILE.size]
	mov	rsi,	qword [r11 + LIMINE_FILE.address]

	; preserve module id
	push	rax

	; magic identificator exist?
	cmp	dword [rsi + rcx - LIB_VFS_length],	LIB_VFS_magic
	jne	.no_vfs	; no

	; register module as memory storage
	mov	al,	KERNEL_STORAGE_TYPE_memory
	call	kernel_storage_register

	; all device slots are used?
	test	rdi,	rdi
	jz	.no_vfs	; ignore device

	; set device properties
	mov	qword [rdi + KERNEL_STORAGE_STRUCTURE.device_blocks],	rcx
	mov	qword [rdi + KERNEL_STORAGE_STRUCTURE.device_first_block],	rsi
	mov	qword [rdi + KERNEL_STORAGE_STRUCTURE.storage_file],	kernel_storage_file
	mov	qword [rdi + KERNEL_STORAGE_STRUCTURE.storage_read],	kernel_storage_read

	; initialize VFS storage
	call	lib_vfs_init

.no_vfs:
	; restore module id
	pop	rax

	; next module?
	inc	rax
	cmp	rax,	qword [rbx + LIMINE_MODULE_RESPONSE.module_count]
	jb	.next	; yes

	;-----------------------------------------------------------------------
	; which storage device contains system files?
	;-----------------------------------------------------------------------

	; limit of devices
	mov	rcx,	KERNEL_STORAGE_limit

	; devices list base address
	mov	rax,	qword [r8 + KERNEL.storage_base_address]

.storage:
	; no more devices?
	dec	rcx
	js	.error	; Geralt: Hmmm...

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
	sub	rax,	qword [r8 + KERNEL.storage_base_address]
	shr	rax,	KERNEL_STORAGE_STRUCTURE_SIZE_shift

	; search for "init" file on storage device
	movzx	ecx,	byte [kernel_exec_file_init_length]
	mov	rsi,	kernel_exec_file_init
	call	kernel_storage_file

	; set storage of kernel process
	mov	qword [r9 + KERNEL_STRUCTURE_TASK.storage],	rax

	; system storage located?
	cmp	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY
	jne	.release	; yes

	; restore original register
	pop	rcx
	pop	rax

	; not a system storage, check next one
	jmp	.storage

.release:
	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; restore preserved registers
	pop	rcx
	pop	rax

	; set root directory of kernel process
	push	qword [rax + KERNEL_STORAGE_STRUCTURE.device_first_block]
	pop	qword [r9 + KERNEL_STRUCTURE_TASK.directory]

	; show information about system storage
	mov	ecx,	kernel_log_system_end - kernel_log_system
	mov	rsi,	kernel_log_system
	call	driver_serial_string

	; convert Bytes to KiB
	mov	rax,	qword [rax + KERNEL_STORAGE_STRUCTURE.device_blocks]
	shr	rax,	STD_SHIFT_1024

	; show size of system storage
	mov	ebx,	STD_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx	; no prefix
	call	driver_serial_value

.end:
	; restore original registers
	pop	r11
	pop	r9
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret

.error:
	; storage is not available
	mov	ecx,	kernel_log_storage_end - kernel_log_storage
	mov	rsi,	kernel_log_storage
	call	driver_serial_string

	; hold the door
	jmp	$