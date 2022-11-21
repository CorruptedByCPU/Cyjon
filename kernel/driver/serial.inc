;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	DRIVER_SERIAL_PORT_COM1	0x03F8
%define	DRIVER_SERIAL_PORT_COM2	0x02F8

struc	DRIVER_SERIAL_STRUCTURE_register
	.data_or_divisor_low			resb	1
	.interrupt_enable_or_divisor_high	resb	1
	.interrupt_identification_or_fifo	resb	1
	.line_control_or_dlab			resb	1
	.modem_control				resb	1
	.line_status				resb	1
	.modem_status				resb	1
	.scratch				resb	1
endstruc