;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_rtc:
	; preserve original register
	push	rax
	push	rbx
	push	rcx

	; connect real-time controller interrupt handler
	mov	rax,	driver_rtc_entry
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	ecx,	KERNEL_IDT_IRQ_offset + DRIVER_RTC_IRQ_number
	call	kernel_idt_mount

	; connect interrupt vector from IDT table in IOAPIC controller
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_RTC_IRQ_number
	mov	ebx,	DRIVER_RTC_IO_APIC_register
	call	kernel_io_apic_connect

	;----------------------------------------------------------------------
	; set RTC interrupt rate at 1024 Hz (even if set by default)
	;----------------------------------------------------------------------

.wait_for_A:
	; get state of register A
	mov	al,	DRIVER_RTC_STATUS_REGISTER_A
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; controller is idle?
	test	al,	DRIVER_RTC_STATUS_REGISTER_A_update_in_progress
	jne	.wait_for_A	; no, wait a little bit longer

	; preserve register A status
	push	rax

	; put controller into modification mode of register A
	mov	al,	DRIVER_RTC_STATUS_REGISTER_A | DRIVER_RTC_STATUS_REGISTER_A_update_in_progress
	out	DRIVER_RTC_PORT_command,	al

	; set calling frequency to 1024 Hz
	mov	al,	DRIVER_RTC_STATUS_REGISTER_A
	out	DRIVER_RTC_PORT_command,	al

	; restore register A status
	pop	rax
	and	al,	0xF0
	or	al,	DRIVER_RTC_STATUS_REGISTER_A_rate
	out	DRIVER_RTC_PORT_data,	al

	;----------------------------------------------------------------------
	; turn on interrupts and change clock range to 24h instead of 12h
	;----------------------------------------------------------------------

.wait_for_B:
	; get state of register B
	mov	al,	DRIVER_RTC_STATUS_REGISTER_B
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; controller is idle?
	test	al,	DRIVER_RTC_STATUS_REGISTER_B_update_in_progress
	jne	.wait_for_B	; no, wait a little bit longer

	; preserve register B status
	push	rax

	; put controller into modification mode of register B
	mov	al,	DRIVER_RTC_STATUS_REGISTER_B | DRIVER_RTC_STATUS_REGISTER_B_update_in_progress
	out	DRIVER_RTC_PORT_command,	al

	; restore register B status
	pop	rax

	; set registry flags
	or	al,	DRIVER_RTC_STATUS_REGISTER_B_24_hour_mode
	or	al,	DRIVER_RTC_STATUS_REGISTER_B_periodic_interrupt
	out	DRIVER_RTC_PORT_data,	al

	;----------------------------------------------------------------------
	; remove overdue interrupts
	;----------------------------------------------------------------------

	; retrieve pending interrupt of real-time controller
	mov	al,	DRIVER_RTC_STATUS_REGISTER_C
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; restore original register
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret