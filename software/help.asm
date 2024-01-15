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

%define	VARIABLE_PROGRAM_NAME		help
%define	VARIABLE_PROGRAM_VERSION	"v0.20"

VARIABLE_PROGRAM_COMMAND_LENGTH		equ	7

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; ustaw wskaźnik na tablice
	mov	rsi,	command_table	; pomiń pierwszą wartość

	; podstawowe zmienne do wyświetlenia tekstu
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

.loop:
	; koniec tablicy?
	cmp	qword [rsi],	VARIABLE_EMPTY
	je	.end

	; wyświetl polecenie
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_PROGRAM_COMMAND_LENGTH
	int	STATIC_KERNEL_SERVICE

	; zachowaj wskaźnik
	push	rsi

	; przesuń wskaźnik na opis polecenia
	mov	rsi,	qword [rsi + VARIABLE_PROGRAM_COMMAND_LENGTH]

	; wyświetl opis polecenia
	mov	ebx,	VARIABLE_COLOR_GRAY
	mov	rcx,	VARIABLE_FULL
	int	STATIC_KERNEL_SERVICE

	; przywróć wskaźnik
	pop	rsi

	; przesuń wskaźnik na następny rekord
	add	rsi,	VARIABLE_PROGRAM_COMMAND_LENGTH + VARIABLE_QWORD_SIZE	; rozmiar komórki 'polecenie' + rozmiar wskaźnika do ciągu opisu

	; kontynuuj
	jmp	.loop

.end:
	; wyjdź z programu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_END
	int	STATIC_KERNEL_SERVICE

command_table:
	db	'bfi    '
	dq	text_bfi

	db	'cat    '
	dq	text_cat

	db	'clear  '
	dq	text_clear

	db	'exit   '
	dq	text_exit

	db	'free   '
	dq	text_free

	db	'help   '
	dq	text_help

	db	'httpd  '
	dq	text_httpd

	db	'ip     '
	dq	text_ip

	db	'kill   '
	dq	text_kill

	db	'ls     '
	dq	text_ls

	db	'moko   '
	dq	text_moko

	db	'ps     '
	dq	text_ps

	; koniec tablicy
	dq	VARIABLE_EMPTY

; wczytaj lokalizacje programu systemu
%push
	%defstr		%$system_locale		VARIABLE_KERNEL_LOCALE
	%defstr		%$process_name		VARIABLE_PROGRAM_NAME
	%strcat		%$include_program_locale,	"software/", %$process_name, "/locale/", %$system_locale, ".asm"
	%include	%$include_program_locale
%pop
