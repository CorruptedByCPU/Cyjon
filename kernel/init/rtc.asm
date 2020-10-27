;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_init_rtc:
	; pobierz stan rejestru A
	mov	al,	DRIVER_RTC_PORT_STATUS_REGISTER_A
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; aktualizacja w toku?
	test	al,	DRIVER_RTC_PORT_STATUS_REGISTER_A_update_in_progress
	jne	kernel_init_rtc	; tak, sprawdź raz jeszcze

	; ustaw częstotliwość wywoływania przerwania na 1024 Hz
	mov	al,	DRIVER_RTC_PORT_STATUS_REGISTER_A
	out	DRIVER_RTC_PORT_command,	al
	mov	al,	DRIVER_RTC_PORT_STATUS_REGISTER_A_rate | DRIVER_RTC_PORT_STATUS_REGISTER_A_divider
	out	DRIVER_RTC_PORT_data,	al

	; włącz: tryb 24 godzinny, czas w formacie binarnym oraz przerwania
	mov	al,	DRIVER_RTC_PORT_STATUS_REGISTER_B
	out	DRIVER_RTC_PORT_command,	al
	mov	al,	DRIVER_RTC_PORT_STATUS_REGISTER_B_24_hour_mode | DRIVER_RTC_PORT_STATUS_REGISTER_B_binary_mode | DRIVER_RTC_PORT_STATUS_REGISTER_B_periodic_interrupt
	out	DRIVER_RTC_PORT_data,	al

	; ustaw CMOS na rejestr C
	mov	al,	DRIVER_RTC_PORT_STATUS_REGISTER_C
	out	DRIVER_RTC_PORT_command,	al

	; pobierz status
	in	al,	DRIVER_RTC_PORT_data

	; zarejestruj procedurę obsługi przerwania zegara czasu rzeczywistego w tablicy IDT
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_RTC_IRQ_number
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	rdi,	driver_rtc
	call	kernel_idt_mount

	; podłącz wektor przerwania z tablicy IDT w kontrolerze I/O APIC
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_RTC_IRQ_number
	mov	ebx,	DRIVER_RTC_IO_APIC_register
	call	kernel_io_apic_connect

	; włącz obsługę przerwań
	sti
