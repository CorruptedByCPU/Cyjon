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

	; by default file does not exist
	mov	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY

	; restore original registers
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
kernel_storage_read:
	; preserve original registers
	push	rax

	; restore original registers
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
	cmp	byte [rdi + KERNEL_STORAGE_STRUCTURE.flags],	EMPTY
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
	mov	al,	KERNEL_STORAGE_FLAG_used
	lock xchg	byte [rdi + KERNEL_STORAGE_STRUCTURE.flags],	al
	jnz	.next	; could not mark a slot

.end:
	; restore original registers
	pop	r8
	pop	rcx
	pop	rax

	; return from routine
	ret