;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_panic_memory:
	; komunikat błędu
	mov	rsi,	kernel_init_string_error_memory_low

;===============================================================================
; wejście:
;	rbp - wskaźnik do ciągu znaków, zakończony terminatorem
kernel_panic:
	; wypisz komunikat na porcie COM1
	call	driver_serial_send

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

	macro_debug	"kernel_panic"
