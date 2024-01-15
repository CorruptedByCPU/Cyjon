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

%define	VARIABLE_PROGRAM_NAME		ip
%define	VARIABLE_PROGRAM_NAME_CHARS	2
%define	VARIABLE_PROGRAM_VERSION	"v0.3"

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
	jbe	.no_option

	; pomiń nazwę procesu w argumentach
	add	rdi,	VARIABLE_PROGRAM_NAME_CHARS
	sub	rcx,	VARIABLE_PROGRAM_NAME_CHARS

	; poszukaj adresu IP w argumentach
	call	library_find_first_word
	jc	.no_option	; brak argumentów

	; IPv4
	mov	r8,	4
	mov	rsi,	variable_ipv4

.digit:
	; zachowaj rozmiar argumentu
	push	rcx

	; pobierz adres i rozmiar w znakach pierwszej liczby
	call	library_find_first_number
	jc	.ip_error

	; zmniejsz rozmiar argumentu o offset
	sub	qword [rsp],	rdx

	; przelicz słowo na liczbę
	mov	rbx,	10	; system dziesiętny
	call	library_string_to_number
	jc	.ip_error

	; czy liczba jest niezgodna z protokołem IP?
	mov	bl,	VARIABLE_FULL
	cmp	rax,	rbx
	ja	.ip_error

	; zapisz liczbę
	mov	byte [rsi],	al
	inc	rsi

	; przesuń wskaźnik na następną liczbę w ciągu argumentów
	add	rdi,	rcx
	; zmniejsz rozmiar argumentu o liczbę
	sub	qword [rsp],	rcx

	; przywróć rozmiar argumentu
	pop	rcx

	; koniec adresu IP?
	dec	r8
	jnz	.digit

	; koniec znaków/cyfr w argumencie?
	cmp	rcx,	VARIABLE_EMPTY
	jne	.ip_error

	; zmień adres IP dla interfejsu sieciowego
	mov	ax,	VARIABLE_KERNEL_SERVICE_NETWORK_IP_SET
	mov	ebx,	dword [variable_ipv4]
	int	STATIC_KERNEL_SERVICE

	; koniec
	jmp	.end

.no_option:
	; pobierz adres IP
	mov	ax,	VARIABLE_KERNEL_SERVICE_NETWORK_IP_GET
	int	STATIC_KERNEL_SERVICE

	; sparwdź czy karta sieciowa ma ustawiony adres IP
	cmp	rbx,	VARIABLE_EMPTY
	je	.end

	; zapamiętaj
	mov	r10,	rbx

	; domyślny kolor tekstu
	mov	bl,	VARIABLE_COLOR_DEFAULT
	; liczby wyświetlaj w systemie dziesiętnym bez prefiksu
	mov	cx,	0x000A
	; domyślny kolor tła
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	; separator liczb
	mov	rsi,	text_dot
	; ilość liczb w adresie IP
	mov	r9,	4

.loop:
	; wyświetl adres IP
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	r8b,	r10b
	int	STATIC_KERNEL_SERVICE

	; wyświelono liczbę, koniec?
	dec	r9
	cmp	r9,	VARIABLE_EMPTY
	je	.end

	; wyświetl separator
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	int	STATIC_KERNEL_SERVICE

	; następna liczba z adresu IP
	shr	r10,	8

	; kontynuuj
	jmp	.loop

.end:
	; koniec działania procesu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_END
	int	STATIC_KERNEL_SERVICE

.ip_error:
	; wyświetl informacje o błędzie
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	bl,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_error
	int	STATIC_KERNEL_SERVICE

	; koniec
	jmp	.end

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

variable_ipv4	dd	VARIABLE_EMPTY
text_dot	db	".", VARIABLE_ASCII_CODE_TERMINATOR

end:
