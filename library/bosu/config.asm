;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

LIBRARY_BOSU_WINDOW_NAME_length			equ	23
LIBRARY_BOSU_WINDOW_BACKGROUND_color		equ	0x00151515

LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel	equ	0x01
LIBRARY_BOSU_WINDOW_BORDER_color		equ	0x0028282800303030

;-------------------------------------------------------------------------------
LIBRARY_BOSU_WINDOW_FLAG_visible		equ	1 << 0	; okno widoczne
LIBRARY_BOSU_WINDOW_FLAG_flush			equ	1 << 1	; okno wymaga przerysowania
LIBRARY_BOSU_WINDOW_FLAG_fixed_xy		equ	1 << 2	; okno nieruchome na osi X,Y
LIBRARY_BOSU_WINDOW_FLAG_fixed_z		equ	1 << 3	; okno nieruchome na osi Z
LIBRARY_BOSU_WINDOW_FLAG_fragile		equ	1 << 4	; okno ukrywane przy wystąpieniu akcji z LPM lub PPM
LIBRARY_BOSU_WINDOW_FLAG_arbiter		equ	1 << 6	; nadobiekt
							; powyżej 7, przeznaczone dla GUI
LIBRARY_BOSU_WINDOW_FLAG_unregistered		equ	1 << 8	; nie rejestruj okna w menedżerze okien
LIBRARY_BOSU_WINDOW_FLAG_header			equ	1 << 9	; pokaż nagłówek okna
LIBRARY_BOSU_WINDOW_FLAG_border			equ	1 << 10	; rysuj krawędź wokół okna
LIBRARY_BOSU_WINDOW_FLAG_BUTTON_close		equ	1 << 11 ; przycisk zamknięcia okna
LIBRARY_BOSU_WINDOW_FLAG_BUTTON_min		equ	1 << 12 ; przycisk minimalizacji okna
;-------------------------------------------------------------------------------

LIBRARY_BOSU_ELEMENT_TYPE_none			equ	0x00
LIBRARY_BOSU_ELEMENT_TYPE_header		equ	0x01
LIBRARY_BOSU_ELEMENT_TYPE_label			equ	0x02
LIBRARY_BOSU_ELEMENT_TYPE_draw			equ	0x03
LIBRARY_BOSU_ELEMENT_TYPE_chain			equ	0x04
LIBRARY_BOSU_ELEMENT_TYPE_button		equ	0x05
LIBRARY_BOSU_ELEMENT_TYPE_taskbar		equ	0x06
LIBRARY_BOSU_ELEMENT_TYPE_button_close		equ	0x07
LIBRARY_BOSU_ELEMENT_TYPE_button_minimize	equ	0x08
LIBRARY_BOSU_ELEMENT_TYPE_button_maximize	equ	0x09
LIBRARY_BOSU_ELEMENT_TYPE_corrupted		equ	0xFF

LIBRARY_BOSU_ELEMENT_HEADER_HEIGHT_pixel	equ	18
LIBRARY_BOSU_ELEMENT_HEADER_PADDING_LEFT_pixel	equ	0x04
LIBRARY_BOSU_ELEMENT_HEADER_FOREGROUND_color	equ	0x00F5F5F5
LIBRARY_BOSU_ELEMENT_HEADER_BACKGROUND_color	equ	0x00202020

LIBRARY_BOSU_ELEMENT_BUTTON_FOREGROUND_color	equ	0x00F5F5F5
LIBRARY_BOSU_ELEMENT_BUTTON_BACKGROUND_color	equ	0x00303030

LIBRARY_BOSU_ELEMENT_BUTTON_CLOSE_width		equ	LIBRARY_BOSU_ELEMENT_HEADER_HEIGHT_pixel

LIBRARY_BOSU_ELEMENT_TASKBAR_PADDING_LEFT_pixel	equ	0x04
LIBRARY_BOSU_ELEMENT_TASKBAR_FOREGROUND_color	equ	0x00F5F5F5
LIBRARY_BOSU_ELEMENT_TASKBAR_BG_color		equ	0x00282828
LIBRARY_BOSU_ELEMENT_TASKBAR_BG_HIDDEN_color	equ	0x00101010

LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color	equ	0x00BBBBBB
LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color	equ	LIBRARY_BOSU_WINDOW_BACKGROUND_color

struc	LIBRARY_BOSU_STRUCTURE_FIELD
	.x					resb	8
	.y					resb	8
	.width					resb	8
	.height					resb	8
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_WINDOW
	.field					resb	LIBRARY_BOSU_STRUCTURE_FIELD.SIZE
	.address				resb	8
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA
	.size					resb	8
	.flags					resb	8
	.id					resb	8
	.length					resb	1
	.name					resb	LIBRARY_BOSU_WINDOW_NAME_length
	;--- dane specyficzne dla Bosu
	.scanline_byte				resb	8
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_TYPE
	.set					resb	4
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT
	.size					resb	8
	.field					resb	LIBRARY_BOSU_STRUCTURE_FIELD.SIZE
	.event					resb	8
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_HEADER
	.type					resb	LIBRARY_BOSU_STRUCTURE_TYPE.SIZE
	.size					resb	8
	.length					resb	1
	.string:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL
	.type					resb	LIBRARY_BOSU_STRUCTURE_TYPE.SIZE
	.element				resb	LIBRARY_BOSU_STRUCTURE_ELEMENT.SIZE
	.length					resb	1
	.string:
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON
	.type					resb	LIBRARY_BOSU_STRUCTURE_TYPE.SIZE
	.element				resb	LIBRARY_BOSU_STRUCTURE_ELEMENT.SIZE
	.length					resb	1
	.string:
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON_CLOSE
	.type					resb	LIBRARY_BOSU_STRUCTURE_TYPE.SIZE
	.size					resb	8
	.event					resb	8
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON_MINIMIZE
	.type					resb	LIBRARY_BOSU_STRUCTURE_TYPE.SIZE
	.size					resb	8
	.event					resb	8
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON_MAXIMIZE
	.type					resb	LIBRARY_BOSU_STRUCTURE_TYPE.SIZE
	.size					resb	8
	.event					resb	8
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR
	.type					resb	LIBRARY_BOSU_STRUCTURE_TYPE.SIZE
	.element				resb	LIBRARY_BOSU_STRUCTURE_ELEMENT.SIZE
	.background				resb	4
	.length					resb	1
	.string:
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_DRAW
	.type					resb	LIBRARY_BOSU_STRUCTURE_TYPE.SIZE
	.element				resb	LIBRARY_BOSU_STRUCTURE_ELEMENT.SIZE
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN
	.type					resb	LIBRARY_BOSU_STRUCTURE_TYPE.SIZE
	.size					resb	8	; rozmiar przestrzeni w Bajtach
	.address				resb	8
	.SIZE:
endstruc
