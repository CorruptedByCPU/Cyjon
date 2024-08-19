;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; in:
;	al - device type
;	
; out:
;	rdi - pointer to device entry
;		or EMPTY if no available entry
kernel_storage_register:
	; preserve original registers
	push	rax
	push	rcx
	push	r8

	; global kernel environment variables/functions/rountines
	mov	r8,	qword [kernel]

	; acquire exclusive access
	MACRO_LOCK	storage_semaphore

	; devices limit
	mov	rcx,	KERNEL_STORAGE_limit

	; properties of first device entry
	mov	rdi,	qword [r8 + KERNEL.storage_base_address]

.next:
	; entry available?
	cmp	byte [rdi + KERNEL_STRUCTURE_STORAGE.device_type],	EMPTY
	je	.register	; yes

	; next entry
	add	rdi,	KERNEL_STRUCTURE_STORAGE.SIZE

	; end of devices list?
	dec	rcx
	jnz	.next	; no

	; no free entry
	xor	edi,	edi

	; end
	jmp	.end

.register:
	; mark entry as in use
	mov	byte [rdi + KERNEL_STRUCTURE_STORAGE.device_type],	al

.end:
	; unlock access
	MACRO_UNLOCK	storage_semaphore

	; restore original registers
	pop	r8
	pop	rcx
	pop	rax

	; return from routine
	ret