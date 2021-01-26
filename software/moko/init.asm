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

	; usuń białe znaki z początku i końca ciągu
	macro_library	LIBRARY_STRUCTURE_ENTRY.string_trim

.no_arguments:
	; przygotuj właściwości przestrzeni pod dokument
	call	moko_document_area

	; rozmiar bufora: szerokość_terminala - ilość znaków w moko_string_menu_read - 0x01
	mov	rax,	r8
	sub	rax,	moko_string_menu_read_end - moko_string_menu_read
	dec	rax

	; zachowaj informacje o buforze
	sub	rsp,	rax
	mov	qword [moko_cache_size_byte],	rax
	mov	qword [moko_cache_address],	rsp
