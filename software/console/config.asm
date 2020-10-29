;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

%define CONSOLE_VERSION			"0.25"

CONSOLE_WINDOW_WIDTH_char	equ	44
CONSOLE_WINDOW_HEIGHT_char	equ	16
CONSOLE_WINDOW_WIDTH_pixel	equ	LIBRARY_FONT_WIDTH_pixel * CONSOLE_WINDOW_WIDTH_char
CONSOLE_WINDOW_HEIGHT_pixel	equ	(LIBRARY_FONT_HEIGHT_pixel * CONSOLE_WINDOW_HEIGHT_char) + LIBRARY_BOSU_ELEMENT_HEADER_HEIGHT_pixel

CONSOLE_WINDOW_BACKGROUND_color	equ	0x00000000
