;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; out:
;	al - requested value
driver_rtc_register:
	; preserve original registers
	push	rbx
	push	rax

	; read value from RTC
	xor	eax,	eax
	in	al,	DRIVER_RTC_PORT_data

	; convert value from BCD to Binary
	mov	bl,	al
	and	bl,	0x0F
	and	al,	0xF0
	shr	al,	4
	mul	cl

	; connect and store
	add	al,	bl
	mov	byte [rsp],	al

	; restore ogriginal registers
	pop	rax
	pop	rbx

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
	; preserve original register
	push	rcx

	; ask for RTC controller mode
	mov	al,	DRIVER_RTC_STATUS_REGISTER_B
	out	DRIVER_RTC_PORT_command,	al

	; retrieve answer
	in	al,	DRIVER_RTC_PORT_data

	; by default BCD mode
	mov	cl,	STATIC_NUMBER_SYSTEM_decimal

	; RTC controller operating in Binary mode?
	test	al,	DRIVER_RTC_STATUS_REGISTER_B_data_mode_binary
	jz	.no

	; yes, change value base to hexadecimal
	mov	cl,	STATIC_NUMBER_SYSTEM_hexadecimal

.no:
	; clear time register
	xor	eax,	eax

	; request weekday
	mov	al,	DRIVER_RTC_REGISTER_weekday
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	in	al,	DRIVER_RTC_PORT_data
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request year
	mov	al,	DRIVER_RTC_REGISTER_year
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	call	driver_rtc_register
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request month
	mov	al,	DRIVER_RTC_REGISTER_month
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	call	driver_rtc_register
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request day
	mov	al,	DRIVER_RTC_REGISTER_day_of_month
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	call	driver_rtc_register
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request hour
	mov	al,	DRIVER_RTC_REGISTER_hour
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	call	driver_rtc_register
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request minutes
	mov	al,	DRIVER_RTC_REGISTER_minutes
	out	DRIVER_RTC_PORT_command,	al
	; retrieve and set in place
	call	driver_rtc_register
	shl	rax,	STATIC_MOVE_AL_TO_HIGH_shift

	; request seconds
	mov	al,	DRIVER_RTC_REGISTER_seconds
	out	DRIVER_RTC_PORT_command,	al
	; retrieve
	call	driver_rtc_register

	; restore original register
	pop	rcx

	; return from routine
	ret
