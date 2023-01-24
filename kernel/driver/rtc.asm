;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; void
driver_rtc:
	; preserve original register
	push	rax
	push	rbx
	push	rdi

.wait:
	; get state of register A
	mov	al,	DRIVER_RTC_STATUS_REGISTER_A
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; controller is in idle state?
	test	al,	DRIVER_RTC_STATUS_REGISTER_update_in_progress
	jne	.wait	; no, wait a little bit longer

	; put controller into modification mode of register A
	mov	al,	DRIVER_RTC_STATUS_REGISTER_A | DRIVER_RTC_STATUS_REGISTER_update_in_progress
	out	DRIVER_RTC_PORT_command,	al

	; set calling frequency to 1024 Hz
	mov	al,	DRIVER_RTC_STATUS_REGISTER_A
	out	DRIVER_RTC_PORT_command,	al
	mov	al,	DRIVER_RTC_STATUS_REGISTER_A_rate | DRIVER_RTC_STATUS_REGISTER_A_divider
	out	DRIVER_RTC_PORT_data,	al

	; put controller into modification mode of register B
	mov	al,	DRIVER_RTC_STATUS_REGISTER_B | DRIVER_RTC_STATUS_REGISTER_update_in_progress
	out	DRIVER_RTC_PORT_command,	al

	; retrieve current state of register B
	mov	al,	DRIVER_RTC_STATUS_REGISTER_B
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; set registry flags
	or	al,	DRIVER_RTC_STATUS_REGISTER_B_24_hour_mode
	or	al,	DRIVER_RTC_STATUS_REGISTER_B_data_mode_binary
	or	al,	DRIVER_RTC_STATUS_REGISTER_B_periodic_interrupt
	and	al,	~DRIVER_RTC_STATUS_REGISTER_B_update_ended_interrupt
	and	al,	~DRIVER_RTC_STATUS_REGISTER_B_alarm_interrupt
	; send update
	out	DRIVER_RTC_PORT_data,	al

	; receive pending interrupt of RTC controller
	mov	al,	DRIVER_RTC_STATUS_REGISTER_C
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; connect RTC controller interrupt handler
	mov	rax,	driver_rtc_irq
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	ecx,	KERNEL_IDT_IRQ_offset + DRIVER_RTC_IRQ_number
	call	kernel_idt_update

	; connect interrupt vector from IDT table in I/O APIC controller
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_RTC_IRQ_number
	mov	ebx,	DRIVER_RTC_IO_APIC_register
	call	kernel_io_apic_connect

	; restore oroginal registers
	pop	rdi
	pop	rbx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; void
driver_rtc_irq:
	; preserve original register
	push	rax

	; kernel environment variables/rountines base address
	mov	rax,	qword [kernel_environment_base_address]

	; increment microtime counter
	inc	qword [rax + KERNEL_STRUCTURE.driver_rtc_microtime]

	; we need content of C register
	mov	al,	DRIVER_RTC_STATUS_REGISTER_C
	out	DRIVER_RTC_PORT_command,	al

	; retrieve it
	in	al,	DRIVER_RTC_PORT_data

	; accept this interrupt
	call	kernel_lapic_accept

	; restore original register
	pop	rax

	; return from interrupt
	iretq

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
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request weekday
	mov	al,	DRIVER_RTC_REGISTER_year
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request weekday
	mov	al,	DRIVER_RTC_REGISTER_month
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request weekday
	mov	al,	DRIVER_RTC_REGISTER_day_of_month
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request weekday
	mov	al,	DRIVER_RTC_REGISTER_hour
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request weekday
	mov	al,	DRIVER_RTC_REGISTER_minutes
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request weekday
	mov	al,	DRIVER_RTC_REGISTER_seconds
	out	DRIVER_RTC_PORT_command,	al
	; retrieve
	in	al,	DRIVER_RTC_PORT_data

	; return from routine
	ret