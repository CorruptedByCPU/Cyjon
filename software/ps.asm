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

%define	VARIABLE_PROGRAM_NAME			ps
%define	VARIABLE_PROGRAM_NAME_CHARS		2
%define	VARIABLE_PROGRAM_VERSION		"v0.5"

VARIABLE_PS_COLUMN_FIRST_WIDTH		equ	0x08

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
	jbe	.no_option

	; pomiń nazwę procesu w argumentach
	add	rdi,	VARIABLE_PROGRAM_NAME_CHARS
	sub	rcx,	VARIABLE_PROGRAM_NAME_CHARS

	; poszukaj argumentu
	call	library_find_first_word
	jc	.no_option	; brak argumentów

	; sprawdź czy opcja obsługiwana
	mov	rcx,	text_option_all_end - text_option_all
	mov	rsi,	text_option_all
	call	library_compare_string
	jc	.no_option

	; pokaż ukryte
	mov	byte [variable_hidden_semaphore],	VARIABLE_TRUE

.no_option:
	; pobierz listę aktywnych procesów (prócz jądra systemu)
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_LIST
	int	STATIC_KERNEL_SERVICE

	; pobierz własny numer PID
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_PID
	int	STATIC_KERNEL_SERVICE

	; zachowaj własny numer PID
	push	rcx

	; wyświetl nagłówek
	mov	rax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_header
	int	STATIC_KERNEL_SERVICE

.loop:
	; zachowaj adres rekordu w tablicy
	push	rdi

	; sprawdź czy proces jest demonem
	mov	bx,	STATIC_SERPENTINE_RECORD_BIT_DAEMON
	bt	[rdi + 	VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	bx
	jnc	.color_default

	; wyświetlić ukryte/demony?
	cmp	byte [variable_hidden_semaphore],	VARIABLE_FALSE
	je	.hide

	; demon, kolor ciemno szary
	mov	ebx,	VARIABLE_COLOR_GRAY

	; kontynuuj
	jmp	.color_ok

.color_default:
	; zwykły proces, kolor domyslny
	mov	ebx,	VARIABLE_COLOR_DEFAULT

.color_ok:
	; wyświetl numer PID procesu
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	ecx,	10	; system dziesiętny
	mov	r8,	qword [rdi]

	; sprawdź czy procesem jest jądro systemu
	cmp	r8,	VARIABLE_EMPTY
	ja	.process

	; wyróżnij kolorem jądro systemu
	mov	bl,	VARIABLE_COLOR_LIGHT_BLUE

.process:
	; rekord należy do mnie?
	cmp	r8, qword [rsp + VARIABLE_QWORD_SIZE]
	jne	.other

	; wyróżnij mnie kolorem
	mov	bl,	VARIABLE_COLOR_LIGHT_GREEN

.other:
	; wyświetl
	int	STATIC_KERNEL_SERVICE

	; zachowaj kolor
	push	rbx

	; pobierz pozycje kursora na ekranie
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_GET
	int	STATIC_KERNEL_SERVICE

	; przesuń kursor na ekranie do nastepnej kolumny
	push	rbx
	mov	dword [rsp],	VARIABLE_PS_COLUMN_FIRST_WIDTH	; rozmiar kolumny pierwszej
	pop	rbx

	; ustaw kursor w nowej pozycji
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	int	STATIC_KERNEL_SERVICE

	; przywróć kolor
	pop	rbx

	; wyświetl nazwę procesu
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	; maksymalna ilość znaków na nazwę procesu
	mov	rcx,	VARIABLE_TABLE_SERPENTINE_RECORD.ARGS - VARIABLE_TABLE_SERPENTINE_RECORD.NAME
	mov	rsi,	rdi
	add	rsi,	VARIABLE_TABLE_SERPENTINE_RECORD.NAME
	int	STATIC_KERNEL_SERVICE

	; przesuń kursor do następnej linii
	mov	rsi,	text_paragraph
	int	STATIC_KERNEL_SERVICE

.hide:
	; przywróć adres rekordu w tablicy
	pop	rdi

	; przesuń wskaźnik do następnego rekordu
	add	rdi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

	; sprawdź czy rekord zawiera proces
	cmp	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	VARIABLE_EMPTY
	jne	.loop

	; koniec programu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_END
	int	STATIC_KERNEL_SERVICE

%include	"library/align_address_up_to_page.asm"
%include	"library/find_first_word.asm"
%include	"library/compare_string.asm"

; wczytaj lokalizacje programu systemu
%push
	%defstr		%$system_locale		VARIABLE_KERNEL_LOCALE
	%defstr		%$process_name		VARIABLE_PROGRAM_NAME
	%strcat		%$include_program_locale,	"software/", %$process_name, "/locale/", %$system_locale, ".asm"
	%include	%$include_program_locale
%pop

variable_hidden_semaphore	db	VARIABLE_FALSE

text_option_all			db	"-x"
text_option_all_end:

end:
