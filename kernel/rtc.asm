;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;---------------------------------------------------------------------------------
; void
driver_rtc_entry:
	; turn off Direction Flag
	cld

	; preserve original registers
	push	rax

.loop:
	; get state of register C
	mov	al,	DRIVER_RTC_STATUS_REGISTER_C
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; no more interrupts?
	test	al,	al
	jz	.done	; yes

	; periodic interrupt?
	test	al,	DRIVER_RTC_STATUS_REGISTER_C_interrupt_periodic
	jz	.loop	; no

	; global kernel environment variables/functions
	mov	rax,	qword [kernel_environment_base_address]

	; increase the real-time controller invocation count
	inc	qword [rax + KERNEL.time_rtc]

	; continue
	jmp	.loop

.done:
	; accept current interrupt call
	call	kernel_lapic_accept

	; restore ogirinal registers
	pop	rax

	; return from routine
	iretq
