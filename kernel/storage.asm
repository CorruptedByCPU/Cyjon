;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	rax - device id
;	rcx - length of path
;	rsi - path to file
;	rbp - pointer of file descriptor
kernel_storage_file:
	; preserve original registers
	push	rax
	push	rdi
	push	r8
	push	r10

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; by default file does not exist
	mov	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY

	; stograge base address
	mov	r10,	qword [r8 + KERNEL_STRUCTURE.storage_base_address]

	; device ID overflow?
	cmp	rax,	KERNEL_STORAGE_limit
	jae	.end	; yes, ignore

	; change device ID to offset
	shl	rax,	KERNEL_STORAGE_STRUCTURE_SIZE_shift

	; device type of KERNEL_STORAGE_TYPE_memory?
	cmp	byte [r10 + rax + KERNEL_STORAGE_STRUCTURE.device_type],	KERNEL_STORAGE_TYPE_memory
	jne	.end	; no

	; search for requested file
	mov	rdi,	qword [r10 + rax + KERNEL_STORAGE_STRUCTURE.device_first_block]
	call	lib_vfs_file

.end:
	; restore original registers
	pop	r10
	pop	r8
	pop	rdi
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rax - device ID
;	rsi - file identificator
;	rdi - file data destination
kernel_storage_read:
	; preserve original registers
	push	rax
	push	r8
	push	r10

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; stograge base address
	mov	r10,	qword [r8 + KERNEL_STRUCTURE.storage_base_address]

	; device ID overflow?
	cmp	rax,	KERNEL_STORAGE_limit
	jae	.end	; yes, ignore

	; change device ID to offset
	shl	rax,	KERNEL_STORAGE_STRUCTURE_SIZE_shift

	; device type of KERNEL_STORAGE_TYPE_memory?
	cmp	byte [r10 + rax + KERNEL_STORAGE_STRUCTURE.device_type],	KERNEL_STORAGE_TYPE_memory
	jne	.end	; no

	; load file
	call	lib_vfs_read

.end:
	; restore original registers
	pop	r10
	pop	r8
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	rdi - pointer to storage specification
;		or NULL if no free slots
kernel_storage_register:
	; preserve original registers
	push	rax
	push	rcx
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; limit of devices
	mov	rcx,	KERNEL_STORAGE_limit

	; base address of device list
	mov	rdi,	qword [r8 + KERNEL_STRUCTURE.storage_base_address]

.next:
	; free device slot?
	cmp	byte [rdi + KERNEL_STORAGE_STRUCTURE.device_type],	EMPTY
	je	.register	; yes

	; next slot
	add	rdi,	KERNEL_STORAGE_STRUCTURE.SIZE

	; end of devices list?
	dec	rcx
	jnz	.next	; no

	; no free slots
	xor	edi,	edi

	; end
	jmp	.end

.register:
	; mark slot as used
	lock xchg	byte [rdi + KERNEL_STORAGE_STRUCTURE.device_type],	al
	jnz	.next	; could not mark a slot

.end:
	; restore original registers
	pop	r8
	pop	rcx
	pop	rax

	; return from routine
	ret