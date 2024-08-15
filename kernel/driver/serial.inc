;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef DRIVER_SERIAL
	%define	DRIVER_SERIAL

	%define	DRIVER_SERIAL_PORT_COM1					0x03F8

	%define	DRIVER_SERIAL_REGISTER_data_or_divisor_low		0x00
	%define	DRIVER_SERIAL_REGISTER_interrupt_enable_or_divisor_high	0x01
	%define	DRIVER_SERIAL_REGISTER_interrupt_identification_or_fifo	0x02
	%define	DRIVER_SERIAL_REGISTER_line_control_or_dlab		0x03
	%define	DRIVER_SERIAL_REGISTER_modem_control			0x04
	%define	DRIVER_SERIAL_REGISTER_line_status			0x05
	%define	DRIVER_SERIAL_REGISTER_modem_status			0x06
	%define	DRIVER_SERIAL_REGISTER_scratch				0x07
%endif