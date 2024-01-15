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

%define	VARIABLE_PROGRAM_NAME		init
%define	VARIABLE_PROGRAM_VERSION	"v0.5"

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; wyświetl powitanie
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	bl,	VARIABLE_COLOR_DEFAULT
	mov	cl,	VARIABLE_FULL
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_init
	int	STATIC_KERNEL_SERVICE

	; pierwszą inicjalizacje nie rozpoczynaj od czyszczenia ekranu
	jmp	.start

.reload:
	; wyczyść ekran
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CLEAN	; procedura czyszcząca ekran
	xor	rbx,	rbx	; od początku ekranu
	xor	rcx,	rcx	; cały ekran
	int	STATIC_KERNEL_SERVICE

.start:
	; wyświetl zaproszenie

	; procedura - wyświetl ciąg znaków na ekranie w miejscu kursora
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	cl,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT

	mov	bl,	VARIABLE_COLOR_LIGHT_BLUE
	mov	rsi,	text_welcome
	int	STATIC_KERNEL_SERVICE

	mov	bl,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_separator
	int	STATIC_KERNEL_SERVICE

	mov	bl,	VARIABLE_COLOR_GRAY
	mov	rsi,	text_version
	int	STATIC_KERNEL_SERVICE

	; uruchom proces logowania do konsoli
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_NEW
	mov	ecx,	dword [file_login_name_length]	; ilość znaków w nazwie pliku
	xor	rdx,	rdx	; brak argumentów
	mov	rsi,	file_login	; wskaźnik do nazwy pliku
	int	STATIC_KERNEL_SERVICE

	; sprawdź czy uruchomiono proces
	cmp	rcx,	VARIABLE_EMPTY
	je	.no_process

	; sprawdź czy proces zakończył pracę
	call	check_process_run

	; autoryzacja przyznana, uruchom powłokę systemu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_NEW
	mov	ecx,	dword [file_shell_name_length]
	xor	rdx,	rdx
	mov	rsi,	file_shell
	int	STATIC_KERNEL_SERVICE

	; sprawdź czy uruchomiono proces
	cmp	rcx,	VARIABLE_EMPTY
	je	.no_process

	; sprawdź czy powołoka zakończyła pracę
	call	check_process_run

	; zalokuj dostęp do konsoli
	jmp	.reload

.no_process:
	; wyświetl informacje o braku pamięci
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	bl,	VARIABLE_COLOR_DEFAULT
	mov	cl,	VARIABLE_FULL
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_no_process
	int	STATIC_KERNEL_SERVICE

	; zatrzymaj wykonywanie procesu
	jmp	$

;===============================================================================
; rcx - numer PID procesu do sprawdzenia
check_process_run:
	; zachowaj oryginalne rejestry
	push	rax

	; pobierz informację o procesie
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_CHECK

.wait:
	int	STATIC_KERNEL_SERVICE

	; sprawdź czy proces zakończył pracę
	cmp	rcx,	VARIABLE_EMPTY
	ja	.wait	; jeśli nie, czekaj dalej

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

; wczytaj lokalizacje programu systemu
%push
	%defstr		%$system_locale		VARIABLE_KERNEL_LOCALE
	%defstr		%$process_name		VARIABLE_PROGRAM_NAME
	%strcat		%$include_program_locale,	"software/", %$process_name, "/locale/", %$system_locale, ".asm"
	%include	%$include_program_locale
%pop

text_welcome		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE
			db	"     W a t a h a . n e t", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_separator		db	"   -----------------------", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_version		db	"              Cyjon v", VARIABLE_KERNEL_VERSION, VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

file_login		db	'login'
file_login_name_length	dd	5
file_shell		db	'shell'
file_shell_name_length	dd	5
