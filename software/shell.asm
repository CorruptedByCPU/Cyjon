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

%define	VARIABLE_PROGRAM_NAME		shell
%define	VARIABLE_PROGRAM_VERSION	"v0.50"

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

prestart:
	; wyświetl wstępną informacje przy pierwszym uruchomieniu programu
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_help
	int	STATIC_KERNEL_SERVICE

start:
	; sprawdź pozycję kursora
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_GET
	int	STATIC_KERNEL_SERVICE

	; jeśli kursor znajduje się na początku ekranu, ok
	cmp	ebx,	VARIABLE_EMPTY
	jne	.restart	; wyświetl znak zachęty od nowej linii

	; pobierz od użytkownika ciąg znaków
	mov	rax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_LIGHT_RED	; nie pokazuj hasła
	mov	rcx,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_prompt
	int	STATIC_KERNEL_SERVICE

.loop:
	; pobierz od użytkownika polecenie
	mov	rbx,	VARIABLE_COLOR_DEFAULT	; kolor domyślny
	mov	rcx,	256	; maksymalny rozmiar polecenia do pobrania
	mov	rdi,	command_cache	; gdzie przechować wprowadzony ciąg znaków
	xor	r8,	r8	; bufor nie zawiera danych
	call	library_input

	; czy użytkownik wpisał cokolwiek?
	jnc	.text

.restart:
	; wyświetl znak zachęty od nowej linii
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rbx,	VARIABLE_COLOR_LIGHT_RED
	mov	rcx,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_prompt_with_newline
	int	STATIC_KERNEL_SERVICE

	; kontynuuj
	jmp	.loop

.text:
	; zachowaj ilość znaków w buforze
	push	rcx

	; przejdź do nowej linii
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rcx,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu
	mov	rsi,	text_newline
	int	STATIC_KERNEL_SERVICE

	; przywróć ilość znaków w buforze
	pop	rcx

	; usuń "białe" znaki z poczatku i końca ciągu
	call	library_trim
	; ciąg znaków był pusty?
	cmp	rcx,	VARIABLE_EMPTY
	je	start	; tak

	; zachowaj ilość znaków w buforze
	mov	qword [command_cache_size],	rcx
	; zachowaj wskaźnik nowego początku
	mov	qword [command_cache_trimmed],	rdi

	; znajdź pierwsze słowo (polecenie) do wykonania/uruchomienia
	call	library_find_first_word

	; bufor zawiera słowo?
	jc	start	; jeśli nie, wyświetl znak zachęty od nowej linii

	; sprawdź czy polecenie wewnętrzne 'clear' ---------------------
	mov	rsi,	command_clear
	xchg	cl,	byte [command_clear_count]
	call	library_compare_string	; sprawdź
	xchg	cl,	byte [command_clear_count]

	; nie znaleziono?
	jc	.noClear

	; wyczyść ekran
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CLEAN	; procedura czyszcząca ekran
	xor	rbx,	rbx	; od początku ekranu
	xor	rcx,	rcx	; cały ekran
	int	STATIC_KERNEL_SERVICE

	; restart powłoki
	jmp	start

.noClear:
	; sprawdź czy próba wywołania Incepcji :D ----------------------
	mov	rsi,	command_shell
	xchg	cl,	byte [command_shell_count]
	call	library_compare_string	; sprawdź
	xchg	cl,	byte [command_shell_count]

	; nie znaleziono?
	jc	.noShell

	; wyświetl informację o braku danego programu na partycji systemowej
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rcx,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_inception
	int	STATIC_KERNEL_SERVICE

	; restart powłoki
	jmp	start

.noShell:
	; sprawdź czy próba wywołania zablokowanego programu -----------
	mov	rsi,	command_init
	xchg	cl,	byte [command_init_count]
	call	library_compare_string	; sprawdź
	xchg	cl,	byte [command_init_count]

	; nie znaleziono?
	jc	.noInit

	; wyświetl informację o braku danego programu na partycji systemowej
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rcx,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_blocked
	int	STATIC_KERNEL_SERVICE

	; restart powłoki
	jmp	start

.noInit:
	; sprawdź czy próba wywołania zablokowanego programu -----------
	mov	rsi,	command_login
	xchg	cl,	byte [command_login_count]
	call	library_compare_string	; sprawdź
	xchg	cl,	byte [command_login_count]

	; nie znaleziono?
	jc	.noLogin

	; wyświetl informację o braku danego programu na partycji systemowej
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rcx,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_login
	int	STATIC_KERNEL_SERVICE

	; restart powłoki
	jmp	start

.noLogin:
	; sprawdź czy polecenie wewnętrzne 'exit' ----------------------
	mov	rsi,	command_exit
	xchg	cl,	byte [command_exit_count]
	call	library_compare_string	; sprawdź
	xchg	cl,	byte [command_exit_count]

	; jeśli nie, kontynuuj
	jc	.noExit

	; wyloguj z powłoki systemu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_END
	int	STATIC_KERNEL_SERVICE

.noExit:
	; uruchom program o podanej nazwie
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_NEW
	mov	rsi,	rdi	; załaduj wskaźnik nazwy pliku
	; przekaż listę argumentów do uruchamianego procesu
	mov	rdi,	qword [command_cache_trimmed]
	mov	rdx,	qword [command_cache_size]
	int	STATIC_KERNEL_SERVICE

	; sprawdź czy uruchomiono nowy proces
	cmp	rbx,	VARIABLE_EMPTY
	je	.process

	; pliku nie znaleziono
	mov	rsi,	text_file_not_found
	cmp	rbx,	VARIABLE_PROCESS_ERROR_FILE_NOT_FOUND
	je	.print_error

	; brak zgody na wykonanie
	mov	rsi,	text_file_no_execute
	cmp	rbx,	VARIABLE_PROCESS_ERROR_NO_EXECUTE
	je	.print_error

	; brak wolnej pamięci do uruchomienia programu
	mov	rsi,	text_file_no_free_memory

.print_error:
	; wyświetl informację o braku danego programu na partycji systemowej
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	STATIC_KERNEL_SERVICE

	; pobierz następne polecenie od użytkownika
	jmp	start

.process:
	; sprawdź czy proces zostawić w tle
	mov	al,	VARIABLE_ASCII_CODE_SPACE
	mov	ah,	"&"
	cmp	word [rdi + rdx - 0x02],	ax
	je	start ; nie czekaj na zakończenie procesu

	; sprawdź czy proces istnieje
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_CHECK	; procedura przeszukuje tablice procesów za podanym identyfikatorem w rejestrze RCX

.wait:
	; sprawdź
	int	STATIC_KERNEL_SERVICE

	; sprawdź czy proces zakończył pracę
	cmp	rcx,	VARIABLE_EMPTY
	ja	.wait

	; rozpocznij od nowa pracę powłoki
	jmp	start

%include	'library/input.asm'
%include	'library/find_first_word.asm'
%include	'library/compare_string.asm'
%include	'library/trim.asm'

; wczytaj lokalizacje programu systemu
%push
	%defstr		%$system_locale		VARIABLE_KERNEL_LOCALE
	%defstr		%$process_name		VARIABLE_PROGRAM_NAME
	%strcat		%$include_program_locale,	"software/", %$process_name, "/locale/", %$system_locale, ".asm"
	%include	%$include_program_locale
%pop

command_cache	times	256	db	VARIABLE_EMPTY
				db	VARIABLE_ASCII_CODE_TERMINATOR
command_cache_trimmed		dq	VARIABLE_EMPTY
command_cache_size		dq	VARIABLE_EMPTY

text_prompt_with_newline	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE
text_prompt			db	"localhost / # ", VARIABLE_ASCII_CODE_TERMINATOR
text_newline			db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

command_clear			db	'clear'
command_clear_count		db	5
command_shell			db	'shell'
command_shell_count		db	5
command_init			db	'init'
command_init_count		db	4
command_login			db	'login'
command_login_count		db	5
command_exit			db	'exit'
command_exit_count		db	4
