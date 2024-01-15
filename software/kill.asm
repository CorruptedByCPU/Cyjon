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

%define	VARIABLE_PROGRAM_NAME		kill
%define	VARIABLE_PROGRAM_NAME_CHARS	4
%define	VARIABLE_PROGRAM_VERSION	"v0.1"

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
	cmp	rcx,	0x02
	jbe	.no

	; pomiń nazwę procesu w argumentach
	add	rdi,	VARIABLE_PROGRAM_NAME_CHARS
	sub	rcx,	VARIABLE_PROGRAM_NAME_CHARS

	; poszukaj pierwszego słowa/liczby
	call	library_find_first_word
	jc	.no	; brak argumentów

	; pobierz adres i rozmiar w znakach pierwszej liczby
	call	library_find_first_number
	jc	.something_odd

	; przelicz słowo na liczbę
	mov	rbx,	10	; system dziesiętny
	call	library_string_to_number
	jc	.something_odd

	; zamknij proces o podanym PID
	mov	rcx,	rax
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_KILL
	int	STATIC_KERNEL_SERVICE

	; sprawdź czy wysłano poprawnie sygnał o zamknięcie procesu
	cmp	rcx,	VARIABLE_EMPTY
	ja	.end	; wysłano sygnał o zamknięcie procesu

.something_odd:
	; wyświetl informacje o braku podanego procesu
	mov	rsi,	text_no_exists
	jmp	.error

.no:
	; separator liczb
	mov	rsi,	text_number

.error:
	; domyślny kolor tekstu
	mov	bl,	VARIABLE_COLOR_DEFAULT
	; liczby wyświetlaj w systemie dziesiętnym bez prefiksu
	mov	rcx,	VARIABLE_FULL
	; domyślny kolor tła
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT

	; wyświetl prośbę o podanie numeru PID procesu do zabicia
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	int	STATIC_KERNEL_SERVICE

.end:
	; koniec działania procesu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_END
	int	STATIC_KERNEL_SERVICE

%include	"library/align_address_up_to_page.asm"
%include	"library/find_first_word.asm"
%include	"library/find_first_number.asm"
%include	"library/string_to_number.asm"

; wczytaj lokalizacje programu systemu
%push
	%defstr		%$system_locale		VARIABLE_KERNEL_LOCALE
	%defstr		%$process_name		VARIABLE_PROGRAM_NAME
	%strcat		%$include_program_locale,	"software/", %$process_name, "/locale/", %$system_locale, ".asm"
	%include	%$include_program_locale
%pop

end:
