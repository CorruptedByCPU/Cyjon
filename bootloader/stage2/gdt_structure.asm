;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 16 Bitowy kod programu
[BITS 16]

; umieść tablicę GDT w pełnym adresie
align	0x04

gdt_specification_32bit:
	; deskryptor zerowy
	dw	0x0000	; Limit 15:0
	dw	0x0000	; Baza 15:0
	db	0x00	; Baza 23:16
	db	00000000b	; P, DPL (2 bity), S, Type (4 bity)
	db	00000000b	; G, D/B, Zarezerwowane, AVL, Limit 19:16
	db	0x00	; Baza 31:24

	; deskryptor kodu
	dw	0xffff	; Limit 0:15
	dw	0x0000	; Baza	0:15
	db	0x00	; Baza 23:16
	db	10011000b	; P, DPL (2 bity), 1, 1, C, R, A
	db	11001111b	; G, D/B, Zarezerwowane, AVL, Limit 19:16
	db	0x00	; Baza 31:24

	; deskryptor danych
	dw	0xffff	; Limit 0:15
	dw	0x0000	; Baza	0:15
	db	0x00	; Baza 23:16
	db	10010010b	; P, DPL (2 bity), 1, 0, E, W, A
	db	11001111b	; G, D/B, Zarezerwowane, AVL, Limit 19:16
	db	0x00	; Baza 31:24
gdt_specification_32bit_end:

gdt_structure_32bit:
	dw	gdt_specification_32bit_end - gdt_specification_32bit - 1	; rozmiar
	dd	gdt_specification_32bit	; adres

; rozpocznik tablicę od pełnego adresu
align	0x08

gdt_specification_64bit:
	; deskryptor zerowy
	dw	0x0000	; Limit 15:0
	dw	0x0000	; Baza 15:0
	db	0x00	; Baza 23:16
	db	00000000b	; P, DPL (2 bity), 1, 1, C, R, A
	db	00000000b	; G, D, L, AVL, Limit 19:16
	db	0x00	; Baza 31:24

	; deskryptor kodu
	dw	0x0000	; ignorowany
	dw	0x0000	; ignorowany
	db	0x00	; ignorowany
	db	10011000b	; P, DPL (2 bity), 1, 1, C, ignorowany, ignorowany
	db	00100000b	; ignorowany, D, L, ignorowany, ignorowany 19:16
	db	0x00	; ignorowany

	; deskryptor danych
	dw	0x0000	; ignorowany
	dw	0x0000	; ignorowany
	db	0x00	; ignorowany
	db	10010010b	; P, ignorowany (2 bity), 1, ignorowany, ignorowany, ignorowany/bochs wymaga!!!, ignorowany
	db	00100000b	; ignorowany, D, L, ignorowany, ignorowany 19:16
	db	0x00	; ignorowany
gdt_specification_64bit_end:

gdt_structure_64bit:
	dw	gdt_specification_64bit_end - gdt_specification_64bit - 1	; rozmiar
	dd	gdt_specification_64bit	; adres
