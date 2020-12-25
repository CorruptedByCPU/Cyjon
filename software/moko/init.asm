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

	; wyświetl interfejs użyszkodnika
	call	moko_interface

	; pobierz rozmiar listy argumentów przesłanych do procesu
	pop	rcx

	; przesłano argumenty do procesu?
	test	rcx,	rcx
	jz	.no_arguments	; nie

	; ustaw wskaźnik na listę argumentów
	mov	rsi,	rsp

.no_arguments:
	; przygotuj właściwości przestrzeni pod dokument
	call	moko_document_area
