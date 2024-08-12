;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%define	DRIVER_RTC_IRQ_number					0x08
%define	DRIVER_RTC_IO_APIC_register				KERNEL_IO_APIC_iowin + (DRIVER_RTC_IRQ_number * 0x02)

%define	DRIVER_RTC_Hz						1024

%define	DRIVER_RTC_PORT_command					0x0070
%define	DRIVER_RTC_PORT_data					0x0071

%define	DRIVER_RTC_REGISTER_seconds				0x00
%define	DRIVER_RTC_REGISTER_minutes				0x02
%define	DRIVER_RTC_REGISTER_hour				0x04
%define	DRIVER_RTC_REGISTER_weekday				0x06
%define	DRIVER_RTC_REGISTER_day_of_month			0x07
%define	DRIVER_RTC_REGISTER_month				0x08
%define	DRIVER_RTC_REGISTER_year				0x09

%define	DRIVER_RTC_STATUS_REGISTER_A				0x0A
%define	DRIVER_RTC_STATUS_REGISTER_B				0x0B
%define	DRIVER_RTC_STATUS_REGISTER_C				0x0C

%define	DRIVER_RTC_STATUS_REGISTER_A_rate			0b00000101	; 1024 Hz (32768 >> (0b00000110 - 1))
%define	DRIVER_RTC_STATUS_REGISTER_A_update_in_progress		0b10000000

%define	DRIVER_RTC_STATUS_REGISTER_B_24_hour_mode		0b00000010
%define	DRIVER_RTC_STATUS_REGISTER_B_data_mode_binary		0b00000100
%define	DRIVER_RTC_STATUS_REGISTER_B_periodic_interrupt		0b01000000
%define	DRIVER_RTC_STATUS_REGISTER_B_update_in_progress		0b10000000

%define	DRIVER_RTC_STATUS_REGISTER_C_interrupt_periodic		0b01000000