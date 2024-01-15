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

%define	VARIABLE_PROGRAM_NAME		login
%define	VARIABLE_PROGRAM_VERSION	"v0.2"

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; wyświetl nawe jednostki i prośbę o nazwe konta
	mov	rax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL	; wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_login	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	int	STATIC_KERNEL_SERVICE

	; pobierz od użytkownika ciąg znaków
	mov	rbx,	VARIABLE_COLOR_WHITE
	mov	rcx,	16	; ilość pobieranych znaków
	mov	rdi,	text_login_cache	; gdzie przechować pobrane znaki
	call	library_input

	; wyświetl prośbę o podanie hasła
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL	; wszystkie znaki z ciągu
	mov	rsi,	text_password	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	int	STATIC_KERNEL_SERVICE

	; wyłącz kursor
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_HIDE
	int	STATIC_KERNEL_SERVICE

	; pobierz od użytkownika ciąg znaków
	mov	rax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_BACKGROUND_DEFAULT	; nie pokazuj hasła
	mov	rcx,	16	; ilość pobieranych znaków
	mov	rdi,	text_password_cache	; gdzie przechować pobrane znaki
	call	library_input

	; przesuń kursor na początek linii
	mov	rcx,	VARIABLE_FULL	; wszystkie znaki z ciągu
	mov	rsi,	text_space	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	int	STATIC_KERNEL_SERVICE

	; włącz kursor
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SHOW
	int	STATIC_KERNEL_SERVICE

	; zakończ działanie procesu/programu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_END
	int	STATIC_KERNEL_SERVICE

%include	'library/input.asm'
%include	'library/compare_string.asm'

; wczytaj lokalizacje programu systemu
%push
	%defstr		%$system_locale		VARIABLE_KERNEL_LOCALE
	%defstr		%$process_name		VARIABLE_PROGRAM_NAME
	%strcat		%$include_program_locale,	"software/", %$process_name, "/locale/", %$system_locale, ".asm"
	%include	%$include_program_locale
%pop

text_login_cache	times	16	db	VARIABLE_EMPTY
text_password_cache	times	16	db	VARIABLE_EMPTY
text_space				db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
