;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; zestaw imiennych wartości stałych jądra systemu
%include	'config.asm'

%define	VARIABLE_PROGRAM_NAME			cat
%define	VARIABLE_PROGRAM_NAME_CHARS		3
%define	VARIABLE_PROGRAM_VERSION		"v0.1"

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; pobierz przesłane argumenty
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_ARGS
	mov	rdi,	end
	call	library_align_address_up_to_page
	int	STATIC_KERNEL_SERVICE

	; czy argumenty istnieją?
	cmp	rcx,	VARIABLE_PROGRAM_NAME_CHARS
	jbe	.no_file

	; pomiń nazwę procesu w argumentach
	add	rdi,	VARIABLE_PROGRAM_NAME_CHARS
	sub	rcx,	VARIABLE_PROGRAM_NAME_CHARS

	; poszukaj argumentu
	call	library_find_first_word
	jc	.no_file	; brak argumentów

	; wczytaj plik do pamięci procesu
	mov	ax,	VARIABLE_KERNEL_SERVICE_VFS_FILE_READ
	mov	rsi,	end	; na koniec programu
	xchg	rsi,	rdi
	int	STATIC_KERNEL_SERVICE

	; ustaw licznik (rozmiar pliku w Bajtach)
	mov	r9,	rcx

	; wyświetl zawartość pliku na ekran
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	1	; po jednym znaku
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

.loop:
	; pobierz znak do wyświetlenia
	mov	r8b,	byte [rdi]

	; zignoruj znaki specjalne
	cmp	r8b,	VARIABLE_ASCII_CODE_ENTER
	je	.omit

	cmp	r8b,	VARIABLE_ASCII_CODE_NEWLINE
	je	.return

.continue:
	; wyświetl
	int	STATIC_KERNEL_SERVICE

.omit:
	; pozostały znaki do wyświetlenia?
	dec	r9
	jz	.no_file	; nie

	; kontynuuj z pozostałą zawartością pliku
	inc	rdi
	jmp	.loop

.return:
	; przesuń kursor na początek linii
	mov	r8b,	VARIABLE_ASCII_CODE_ENTER
	int	STATIC_KERNEL_SERVICE

	; wyświetl aktualny znak
	mov	r8b,	VARIABLE_ASCII_CODE_NEWLINE

	; kontynuuj
	jmp	.continue

.no_file:
	; koniec programu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_END
	int	STATIC_KERNEL_SERVICE

%include	"library/align_address_up_to_page.asm"
%include	"library/find_first_word.asm"

end:
