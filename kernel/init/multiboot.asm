;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

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
	dd	init	; początek kodu jądra systemu
	dd	STATIC_EMPTY	; kod jak i dane jądra systemu to cały plik
	dd	STATIC_EMPTY	; brak segmentu BSS
	dd	init	; procedura rozpoczynająca inicjalizację jądra systemu
; wyrównaj rozmiar nagłówka do 16 Bajtów
align	0x10
header_end:
