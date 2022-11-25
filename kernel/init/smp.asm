;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_smp:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; SMP specification available?
	cmp	qword [kernel_limine_smp_request + LIMINE_SMP_REQUEST.response],	EMPTY
	je	.alone	; no

	; initialize all available APs on host
	mov	rsi,	qword [kernel_limine_smp_request + LIMINE_SMP_REQUEST.response]

	; set amount of APs and set pointer to first entry
	mov	rcx,	qword [rsi + LIMINE_SMP_RESPONSE.cpu_count]
	mov	rsi,	qword [rsi + LIMINE_SMP_RESPONSE.cpu_info]

	; ID of current CPU (BSP)
	call	kernel_lapic_id

.next:
	; entries left
	dec	rcx
	js	.alone	; no more APs

	; properties of entry
	mov	rdi,	qword [rsi + rcx * STATIC_PTR_SIZE_byte]

	; it's the BSP?
	cmp	dword [rdi + LIMINE_SMP_INFO.lapic_id],	eax
	je	.next	; yes

	; set jump point of this AP
	mov	qword [rdi + LIMINE_SMP_INFO.goto_address],	kernel_init_ap

	; next AP from list
	jmp	.next

.alone:
	; restore original registers
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; return from routine
	ret