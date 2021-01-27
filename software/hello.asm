;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/hello/config.asm"
	;-----------------------------------------------------------------------

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

	macro_debug	"software: hello"

	;-----------------------------------------------------------------------
	%include	"software/hello/data.asm"
	;-----------------------------------------------------------------------
