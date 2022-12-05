;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; out:
;	r8 - pointer to kernel environment variables/routines
kernel_init_storage:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r11

	; modules available?
	cmp	qword [kernel_limine_module_request + LIMINE_MODULE_REQUEST.response],	EMPTY
	je	.error	; no

	; assign space for storage list
	mov	ecx,	((KERNEL_STORAGE_limit * KERNEL_STORAGE_STRUCTURE.SIZE) + ~STATIC_PAGE_mask) >> STATIC_PAGE_SIZE_shift
	call	kernel_memory_alloc

	; save pointer to storage list
	mov	qword [r8 + KERNEL_STRUCTURE.storage_base_address],	rdi

	; pointer of modules response structure
	mov	rbx,	qword [kernel_limine_module_request + LIMINE_MODULE_REQUEST.response]

	; first entry of modules list
	xor	eax,	eax
	mov	rdx,	qword [rbx + LIMINE_MODULE_RESPONSE.modules]

.next:
	; retrieve entry address
	mov	r11,	qword [rdx + rax * STATIC_PTR_SIZE_byte]

	;-----------------------------------------------------------------------
	; PKG module?
	;----------------------------------------------------------------------

	; properties of module
	mov	rcx,	qword [r11 + LIMINE_FILE.size]
	mov	rsi,	qword [r11 + LIMINE_FILE.address]

	; magic identificator exist?
	cmp	dword [rsi + rcx - LIB_PKG_length],	LIB_PKG_magic
	jne	.no_pkg	; no

	; register module as memory storage
	mov	al,	KERNEL_STORAGE_TYPE_memory
	call	kernel_storage_register

	; all device slots are used?
	test	rdi,	rdi
	jz	.no_pkg	; ignore device

	; set device properties
	mov	qword [rdi + KERNEL_STORAGE_STRUCTURE.device_blocks],	rcx
	mov	qword [rdi + KERNEL_STORAGE_STRUCTURE.device_first_block],	rsi
	mov	qword [rdi + KERNEL_STORAGE_STRUCTURE.storage_file],	kernel_storage_file
	mov	qword [rdi + KERNEL_STORAGE_STRUCTURE.storage_read],	kernel_storage_read

.no_pkg:
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
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.storage_base_address]

.storage:
	; no more devices?
	dec	rcx
	js	.error	; Geralt: Hmmm...

	; search for system files?
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

	; search for "init" file on storage device
	mov	ecx,	KERNEL_EXEC_FILE_INIT_length
	mov	rsi,	kernel_exec_file_init
	call	kernel_storage_file

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

	; show information about system storage
	mov	rsi,	kernel_log_system
	call	driver_serial_string

	; convert Bytes to KiB
	mov	rax,	qword [rax + KERNEL_STORAGE_STRUCTURE.device_blocks]
	shr	rax,	STATIC_DIVIDE_BY_4096_shift

	; show size of system storage
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	call	driver_serial_value

.end:
	; restore original registers
	pop	r11
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
	mov	rsi,	kernel_log_storage
	call	driver_serial_string

	; hold the door
	jmp	$