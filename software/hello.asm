;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"
	%include	"kernel/header/service.inc"
	%include	"kernel/macro/debug.asm"
	;-----------------------------------------------------------------------

; 64 bitowy kod programu
[bits 64]

; adresowanie względne
[default rel]

; położenie kodu programu w pamięci logicznej
[org SOFTWARE_base_address]

;===============================================================================
hello:
	; wyświetl powitanie
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	cl,	hello_string_end - hello_string
	mov	rsi,	hello_string
	int	KERNEL_SERVICE

	; zakończ pracę programu
	xor	ax,	ax
	int	KERNEL_SERVICE

	; debug
	macro_debug	"software: hello"

hello_string	db	"Hello, World!"
hello_string_end:
