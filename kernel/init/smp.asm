;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_smp:
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
	mov	rdi,	qword [rsi + rcx * STD_PTR_SIZE_byte]

	; it's the BSP?
	cmp	dword [rdi + LIMINE_SMP_INFO.lapic_id],	eax
	je	.next	; yes

	; set jump point of this AP
	mov	qword [rdi + LIMINE_SMP_INFO.goto_address],	kernel_init_ap

	; AP is running
	inc	qword [kernel_smp_count]

.wait:
	; wait for AP initialization
	mov	rbx,	qword [r8 + KERNEL.cpu_count]
	cmp	rbx,	qword [kernel_smp_count]
	jne	.wait

	; current AP have higest ID?
	mov	ebx,	dword [rdi + LIMINE_SMP_INFO.lapic_id]
	cmp	ebx,	dword [r8 + KERNEL.lapic_last_id]
	jb	.next	; no

	; remember CPU ID
	mov	dword [r8 + KERNEL.lapic_last_id],	ebx

	; next AP from list
	jmp	.next

.alone:
	; if additional APs were initialized
	cmp	qword [kernel_smp_count],	EMPTY
	je	.free	; no

	; prefix
	mov	ecx,	kernel_log_prefix_end - kernel_log_prefix
	mov	rsi,	kernel_log_prefix
	call	driver_serial_string

	; number of APs initialized
	mov	rax,	qword [kernel_smp_count]
	mov	ebx,	STD_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx	; no prefix
	xor	dl,	dl	; value unsigned
	call	driver_serial_value
	mov	ecx,	kernel_log_smp_end - kernel_log_smp
	mov	rsi,	kernel_log_smp
	call	driver_serial_string

.free:
	; free up reclaimable memory
	jmp	kernel_init_free