;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_init_serial:
	; inicjalizuj urządzenie COM1
	call	driver_serial

	; wyślij komunikat na COM1
	mov	rsi,	kernel_init_string_serial
	call	driver_serial_send
