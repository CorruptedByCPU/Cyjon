;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

%define	PROGRAM_NAME			"console"
%define	PROGRAM_VERSION			"0.26"

CONSOLE_WINDOW_WIDTH_char	equ	46
CONSOLE_WINDOW_HEIGHT_char	equ	16
CONSOLE_WINDOW_WIDTH_pixel	equ	LIBRARY_FONT_WIDTH_pixel * CONSOLE_WINDOW_WIDTH_char
CONSOLE_WINDOW_HEIGHT_pixel	equ	(LIBRARY_FONT_HEIGHT_pixel * CONSOLE_WINDOW_HEIGHT_char) + LIBRARY_BOSU_HEADER_HEIGHT_pixel

CONSOLE_WINDOW_BACKGROUND_color	equ	0x00000000
