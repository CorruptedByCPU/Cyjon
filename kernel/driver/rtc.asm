;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;---------------------------------------------------------------------------------
; void
driver_rtc:
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
	mov	rax,	qword [kernel]

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

;-------------------------------------------------------------------------------
; void
driver_rtc_init:
	; preserve original register
	push	rax
	push	rbx
	push	rcx

	; connect real-time controller interrupt handler
	mov	rax,	driver_rtc
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
	or	al,	DRIVER_RTC_STATUS_REGISTER_B_data_mode_binary
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

;-------------------------------------------------------------------------------
; out:
;	rax - 0x00wwyymmddHHMMSS
;
;	ww - Weekday (Sunday 1, Monday 2, etc.)
;	yy - 20YY
;	mm - Month
;	dd - Day (1..31)
;	HH - Hour (0..23)
;	MM - Minute (0..59)
;	SS - Second (0..59)
driver_rtc_time:
	; clear time register
	xor	eax,	eax

	; request weekday
	mov	al,	DRIVER_RTC_REGISTER_weekday
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STD_MOVE_BYTE

	; request year
	mov	al,	DRIVER_RTC_REGISTER_year
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STD_MOVE_BYTE

	; request month
	mov	al,	DRIVER_RTC_REGISTER_month
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STD_MOVE_BYTE

	; request day
	mov	al,	DRIVER_RTC_REGISTER_day_of_month
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STD_MOVE_BYTE

	; request hour
	mov	al,	DRIVER_RTC_REGISTER_hour
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STD_MOVE_BYTE

	; request minutes
	mov	al,	DRIVER_RTC_REGISTER_minutes
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STD_MOVE_BYTE

	; request seconds
	mov	al,	DRIVER_RTC_REGISTER_seconds
	out	DRIVER_RTC_PORT_command,	al
	; retrieve, already in place
	in	al,	DRIVER_RTC_PORT_data

	; return from routine
	ret