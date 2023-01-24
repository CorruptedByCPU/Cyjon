;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	DRIVER_RTC_Hz						1024

%define	DRIVER_RTC_IRQ_number					0x08
%define	DRIVER_RTC_IO_APIC_register				KERNEL_IO_APIC_iowin + (DRIVER_RTC_IRQ_number * 0x02)

%define	DRIVER_RTC_PORT_command					0x0070
%define	DRIVER_RTC_PORT_data					0x0071

%define	DRIVER_RTC_REGISTER_seconds				0x00
%define	DRIVER_RTC_REGISTER_minutes				0x02
%define	DRIVER_RTC_REGISTER_hour				0x04
%define	DRIVER_RTC_REGISTER_weekday				0x06
%define	DRIVER_RTC_REGISTER_day_of_month			0x07
%define	DRIVER_RTC_REGISTER_month				0x08
%define	DRIVER_RTC_REGISTER_year				0x09

%define	DRIVER_RTC_STATUS_REGISTER_update_in_progress		10000000b

%define	DRIVER_RTC_STATUS_REGISTER_A				0x0A
%define	DRIVER_RTC_STATUS_REGISTER_B				0x0B

%define	DRIVER_RTC_STATUS_REGISTER_A_rate			00000110b	; 1024 Hz
%define	DRIVER_RTC_STATUS_REGISTER_A_divider			00100000b	; 32768 kHz

%define	DRIVER_RTC_STATUS_REGISTER_B_daylight_savings		00000001b
%define	DRIVER_RTC_STATUS_REGISTER_B_24_hour_mode		00000010b
%define	DRIVER_RTC_STATUS_REGISTER_B_data_mode_binary		00000100b	; no BCD
%define	DRIVER_RTC_STATUS_REGISTER_B_square_wave_output		00001000b
%define	DRIVER_RTC_STATUS_REGISTER_B_update_ended_interrupt	00010000b	; announce with interrupt when controller exited modification mode
%define	DRIVER_RTC_STATUS_REGISTER_B_alarm_interrupt		00100000b
%define	DRIVER_RTC_STATUS_REGISTER_B_periodic_interrupt		01000000b

%define	DRIVER_RTC_STATUS_REGISTER_C			0x0C