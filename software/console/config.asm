;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

%define CONSOLE_VERSION			"0.21"

CONSOLE_WINDOW_WIDTH_char	equ	40
CONSOLE_WINDOW_HEIGHT_char	equ	12
CONSOLE_WINDOW_WIDTH_pixel	equ	LIBRARY_FONT_WIDTH_pixel * CONSOLE_WINDOW_WIDTH_char
CONSOLE_WINDOW_HEIGHT_pixel	equ	LIBRARY_FONT_HEIGHT_pixel * CONSOLE_WINDOW_HEIGHT_char

CONSOLE_WINDOW_BACKGROUND_color	equ	0x00000000

struc	CONSOLE_STRUCTURE_META
	.width			resb	2
	.height			resb	2
	.x			resb	2
	.y			resb	2
	.SIZE:
endstruc
