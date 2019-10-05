;================================================================================
; Copyright (C) by Blackend.dev
;================================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"	; globalne
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"	; lokalne
	;-----------------------------------------------------------------------

; 32 bitowy kod inicjalizacyjny jądra systemu
[BITS 32]

; położenie kodu jądra systemu w pamięci fizycznej
[ORG KERNEL_BASE_address]

_start:
	; koryguj zawartość nagłówka
	mov	dword [header],	"ZERO"

	; wykonaj poniższy kod, jeśli nie został rozpoznany nagłówek
	jmp	init

HEADER_MAGIC		equ	0x1BADB002

HEADER_FLAG_align	equ	1 << 0
HEADER_FLAG_memory_map	equ	1 << 1
HEADER_FLAG_header	equ	1 << 16
HEADER_FLAG_default	equ	HEADER_FLAG_align | HEADER_FLAG_memory_map | HEADER_FLAG_header

HEADER_CHECKSUM		equ	-(HEADER_FLAG_default + HEADER_MAGIC)

; wyrównaj pozycję nagłówka do podwójnego słowa
align	0x04
header:
	dd	HEADER_MAGIC	; czysta magija
	dd	HEADER_FLAG_default	; flagi
	dd	HEADER_CHECKSUM	; suma kontrolna
	dd	header	; wskaźnik początku nagłówka
	dd	_start	; początek kodu jądra systemu
	dd	STATIC_EMPTY	; kod jak i dane jądra systemu to cały plik
	dd	STATIC_EMPTY	; brak segmentu BSS
	dd	init	; procedura rozpoczynająca inicjalizację jądra systemu
; wyrównaj rozmiar nagłówka do 16 Bajtów
align	0x10
header_end:

init:
	;-----------------------------------------------------------------------
	; Init - inicjalizacja środowiska pracy jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init.asm"

kernel:
	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

	;-----------------------------------------------------------------------
	%include	"kernel/macro/close.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/panic.asm"
	%include	"kernel/page.asm"
	%include	"kernel/memory.asm"
	;-----------------------------------------------------------------------
	%include	"library/page_align_up.asm"
	%include	"library/page_from_size.asm"
	;-----------------------------------------------------------------------

kernel_end:
