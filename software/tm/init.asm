;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	; poproś właściciela strumienia o zmianę tytułu okna (jeśli istnieje)
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_console_header_end - tm_string_console_header
	mov	rsi,	tm_string_console_header
	int	KERNEL_SERVICE

	; wyczyść przestrzeń znakową
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_init_end - tm_string_init
	mov	rsi,	tm_string_init
	int	KERNEL_SERVICE

	; wyświetl niezmienne elementy interfejsu
	call	tm_static
