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

%define	VARIABLE_PROGRAM_NAME		ls
%define	VARIABLE_PROGRAM_NAME_CHARS	2
%define	VARIABLE_PROGRAM_VERSION	"v0.2"

; struktura supła w drzewie katalogu
struc STRUCTURE_KNOT
	.id		resq	1
	.permission	resq	1
	.size		resq	1
	.chars		resq	1
	.name		resb	32	; ilość znaków na nazwę pliku
	.SIZE		resb	1	; rozmiar struktury w Bajtach
endstruc

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; załaduj katalog główny na koniec programu
	mov	rdi,	end

	; wczytaj plik katalog główny
	mov	ax,	VARIABLE_KERNEL_SERVICE_VFS_DIR_ROOT
	int	STATIC_KERNEL_SERVICE

	; przystępujemy do wyświetlenia zawartości
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING

	; oblicz koniec "tablicy" katalogu
	add	rdx,	rdi

	; ustaw wskaźnik początku tablicy
	mov	rsi,	rdi

.loop:
	; sprawdź czy koniec rekordów
	cmp	qword [rsi + STRUCTURE_KNOT.size],	VARIABLE_EMPTY
	je	.end

	; pobierz rozmiar nazwy pliku w znakach
	movzx	rcx,	byte [rsi + STRUCTURE_KNOT.chars]

	; załaduj kolor dla zwykłego pliku
	mov	ebx,	VARIABLE_COLOR_DEFAULT

	push	rdx
	push	rsi

	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

	; przesuń wskaźnik na ciąg znaków przedstawiający nazwe pliku
	add	rsi,	STRUCTURE_KNOT.name
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; wyświetl odstęp pomięczy nazwami
	mov	cl,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu zakończonego terminatorem
	mov	rsi,	text_separate
	int	STATIC_KERNEL_SERVICE

	pop	rsi
	pop	rdx

.leave:
	; przesuń wskaźnik na następny rekord
	add	rsi,	STRUCTURE_KNOT.SIZE

	; wyświetl pozostałe pliki zawarte w tablicy
	jmp	.loop

.end:
	; program kończy działanie
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_END
	int	STATIC_KERNEL_SERVICE	; wykonaj

variable_semaphore_all	db	VARIABLE_EMPTY

text_separate	db	'  ', VARIABLE_ASCII_CODE_TERMINATOR
text_new_line	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

end:
