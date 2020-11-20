;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
ls_init:
	; wyłącz wirtualny kursor (nie jest potrzebny, program nie wchodzi w interakcje, oszczędzamy czas procesora)
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	ls_string_init_end - ls_string_init
	mov	rsi,	ls_string_init
	int	KERNEL_SERVICE

	; pobierz rozmiar listy argumentów przesłanych do procesu
	pop	rcx

	; przesłano argumenty do procesu?
	test	rcx,	rcx
	jz	.no_arguments	; nie

	; ustaw wskaźnik na listę argumentów
	mov	rsi,	rsp

	; usuń z początku i końca listy wszystkie białe znaki
	call	library_string_trim
	jnc	.trimmed	; przetworzono

.no_arguments:
	; wyświetl listę plików w katalogu roboczym procesu
	mov	ecx,	ls_path_local_end - ls_path_local
	mov	rsi,	ls_path_local

.trimmed:
