;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/ls/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
ls:
	; inicjalizuj środowisko pracy
	%include	"software/ls/init.asm"

	; wczytaj listę plików z podanego katalogu
	mov	ax,	KERNEL_SERVICE_VFS_dir
	int	KERNEL_SERVICE
	jc	.error	; błędna ścieżka do katalogu lub pliku nie znaleziono

	; ustaw licznik wpisów
	mov	rbx,	rcx

.loop:
	; domyślnie kolorystyka dla pliku
	mov	ecx,	ls_string_color_file_end - ls_string_color_file
	mov	rsi,	ls_string_color_file

	; plik typu katalog?
	test	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_directory
	jz	.no_directory	; nie

	; ustaw kolorystykę dla katalogu
	mov	rsi,	ls_string_color_directory

.no_directory:
	; zmień kolorystykę
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	int	KERNEL_SERVICE

	; ustaw wskaźnik na nazwę pliku
	mov	rsi,	rdi
	add	rsi,	KERNEL_VFS_STRUCTURE_KNOT.name

	; plik jest ukryty?
	cmp	byte [rsi],	STATIC_SCANCODE_DOT
	je	.hidden	; tak

	; wyświetl nazwę pliku
	mov	cl,	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.length]
	int	KERNEL_SERVICE

	; wyświetl separator
	mov	cl,	ls_string_separator_end - ls_string_separator
	mov	rsi,	ls_string_separator
	int	KERNEL_SERVICE

.hidden:
	; wyświetlono wszyskie pliki?
	dec	rbx
	jz	.end	; tak

	; przesuń wskaźnik na następny plik
	add	rdi,	KERNEL_VFS_STRUCTURE_KNOT.SIZE

	; wyświetl pozostałe pliki
	jmp	.loop

.error:
	; wyświetl komunikat
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	ls_string_error_not_found_end - ls_string_error_not_found
	mov	rsi,	ls_string_error_not_found
	int	KERNEL_SERVICE

.end:
	; zakończ pracę programu
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: ls"

	;-----------------------------------------------------------------------
	%include	"software/ls/data.asm"
	;-----------------------------------------------------------------------
