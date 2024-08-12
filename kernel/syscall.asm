;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

; information for linker
section	.text

; align routine
align	0x08,	db	0x00
kernel_syscall:
	; keep RIP and EFLAGS registers of process
	xchg	qword [rsp + 0x08],	rcx
	xchg	qword [rsp],	r11

	; feature available?
	cmp	rax,	(kernel_service_list_end - kernel_service_list) / 0x08
	jnb	.return	; no

	; preserve original registers
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; execute kernel function according to parameter in RAX
	call	qword [kernel_service_list + rax * STATIC_QWORD_SIZE_byte]

	; restore original registers
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

.return:
	; restore the RIP and EFLAGS registers of the process
	xchg	qword [rsp],	r11
	xchg	qword [rsp + STATIC_QWORD_SIZE_byte],	rcx

	; return to process code
	o64	sysret