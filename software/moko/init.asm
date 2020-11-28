;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	; poproś właściciela strumienia o zmianę tytułu okna (jeśli istnieje)
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_console_header_end - moko_string_console_header
	mov	rsi,	moko_string_console_header
	int	KERNEL_SERVICE

	; przygotuj właściwości przestrzeni pod dokument
	call	moko_document_area

	; wyświetl interfejs użyszkodnika
	call	moko_interface
