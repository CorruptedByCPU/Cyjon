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

%define	VARIABLE_PROGRAM_NAME		free
%define	VARIABLE_PROGRAM_VERSION	"v0.6"

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; wyświetl nagłówek i pierwszą nazwę wiersza tabeli
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	ecx,	VARIABLE_FULL
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_header
	int	STATIC_KERNEL_SERVICE

	; pobierz informacje o pamięci systemu
	mov	ax,	VARIABLE_KERNEL_SERVICE_SYSTEM_MEMORY
	int	STATIC_KERNEL_SERVICE

	; pobierz pozycję kursora na ekranie
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_GET
	int	STATIC_KERNEL_SERVICE

	; zapamiętaj
	push	rbx

	; TOTAL ----------------------------------------------------------------
	; wyświetl rozmiar całkowity pamięci
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	ebx,	VARIABLE_COLOR_WHITE
	mov	ecx,	VARIABLE_SYSTEM_DECIMAL
	mov	r8,	r11	; ilość stron
	shl	r8,	VARIABLE_MULTIPLE_BY_4	; strony zamień na KiB
	int	STATIC_KERNEL_SERVICE

	; przesuń kursor na pozycję kolumny USED
	mov	dword [rsp],	22

	; wyświetl typ rozmiaru i ustaw kursor na następną kolumnę
	call	.next_column

	; USED -----------------------------------------------------------------
	; wyświetl rozmiar wykorzystanej pamięci
	mov	r8,	r11	; rozmiar całkowity
	sub	r8,	r12	; zmniejszony o rozmiar wolnej
	shl	r8,	VARIABLE_MULTIPLE_BY_4	; strony zamień na KiB
	int	STATIC_KERNEL_SERVICE

	; przesuń kursor na pozycję kolumny USED
	mov	dword [rsp],	36

	; wyświetl typ rozmiaru i ustaw kursor na następną kolumnę
	call	.next_column

	; FREE -----------------------------------------------------------------
	; wyświetl rozmiar wolnej pamięci
	mov	r8,	r12
	shl	r8,	VARIABLE_MULTIPLE_BY_4	; strony zamień na KiB
	int	STATIC_KERNEL_SERVICE

	; przesuń kursor na pozycję kolumny USED
	mov	dword [rsp],	50

	; wyświetl typ rozmiaru i ustaw kursor na następną kolumnę
	call	.next_column

	; CACHED ---------------------------------------------------------------
	; wyswietl rozmiar pamięci buforowanej
	mov	r8,	r14
	shl	r8,	VARIABLE_MULTIPLE_BY_4	; strony zamień na KiB
	int	STATIC_KERNEL_SERVICE

	; przesuń kursor na pozycję kolumny USED
	mov	dword [rsp],	64

	; wyświetl typ rozmiaru i ustaw kursor na następną kolumnę
	call	.next_column

	; SHARED ---------------------------------------------------------------
	; wyświetl rozmiar pamięci współdzielonej
	mov	r8,	r15
	shl	r8,	VARIABLE_MULTIPLE_BY_4	; strony zamień na KiB
	int	STATIC_KERNEL_SERVICE

	; wyświetl typ rozmiaru
	call	.next_column

	; koniec programu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_END
	int	STATIC_KERNEL_SERVICE

.next_column:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx

	; wyświetl typ rozmiaru
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_kib
	int	STATIC_KERNEL_SERVICE

	; zatwierdź
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [rsp + VARIABLE_QWORD_SIZE * 3]
	int	STATIC_KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rbx
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

text_kib	db	" KiB", VARIABLE_ASCII_CODE_TERMINATOR
text_paragraph	db	VARIABLE_ASCII_CODE_RETURN
