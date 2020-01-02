;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

HEADER_MAGIC			equ	0x1BADB002

HEADER_FLAG_align		equ	1 << 0
HEADER_FLAG_memory_map		equ	1 << 1
HEADER_FLAG_video		equ	1 << 2
HEADER_FLAG_header		equ	1 << 16
HEADER_FLAG_default		equ	HEADER_FLAG_align | HEADER_FLAG_memory_map | HEADER_FLAG_video | HEADER_FLAG_header

HEADER_CHECKSUM			equ	-(HEADER_FLAG_default + HEADER_MAGIC)

struc	HEADER_multiboot
	.flags			resb	4
	.unsupported0		resb	40
	.mmap_length		resb	4
	.mmap_addr		resb	4
	.unsupported1		resb	36
	.framebuffer_addr	resb	8
	.framebuffer_pitch	resb	4
	.framebuffer_width	resb	4
	.framebuffer_height	resb	4
	.framebuffer_bpp	resb	1
	.framebuffer_type	resb	1
	.color_info		resb	6
endstruc

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
	dd	STATIC_EMPTY	; liniowa przestrzeń pamięci karty graficznej
	dd	KERNEL_VIDEO_WIDTH_pixel
	dd	KERNEL_VIDEO_HEIGHT_pixel
	dd	KERNEL_VIDEO_DEPTH_bit

; wyrównaj rozmiar nagłówka do 16 Bajtów
align	0x10
header_end:
