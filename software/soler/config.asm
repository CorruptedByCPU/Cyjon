;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

%define	PROGRAM_NAME			"soler"
%define	PROGRAM_VERSION			"0.2"

SOLER_INPUT_FLAG_float_first		equ	00000001b
SOLER_INPUT_FLAG_float_second		equ	00000010b

SOLER_INPUT_SIZE_overflow		equ	21
SOLER_INPUT_SIZE_char			equ	16
SOLER_INPUT_WIDTH_pixel			equ	SOLER_INPUT_SIZE_char * LIBRARY_FONT_WIDTH_pixel + 0x03	; +0x03 korekta do wszystkich wyliczeń

SOLER_WINDOW_WIDTH_element		equ	4
SOLER_WINDOW_HEIGHT_element		equ	6

SOLER_WINDOW_ELEMENT_WIDTH_pixel	equ	SOLER_INPUT_WIDTH_pixel / SOLER_WINDOW_WIDTH_element
SOLER_WINDOW_ELEMENT_HEIGHT_pixel	equ	SOLER_WINDOW_ELEMENT_WIDTH_pixel
SOLER_WINDOW_ELEMENT_MARGIN_pixel	equ	1
SOLER_WINDOW_ELEMENT_AREA_pixel		equ	SOLER_WINDOW_ELEMENT_WIDTH_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel

SOLER_WINDOW_WIDTH_pixel		equ	SOLER_INPUT_WIDTH_pixel + (SOLER_WINDOW_PADDING_pixel << STATIC_MULTIPLE_BY_2_shift)
SOLER_WINDOW_HEIGHT_pixel		equ	(SOLER_WINDOW_HEIGHT_element + SOLER_WINDOW_ELEMENT_MARGIN_pixel) * SOLER_WINDOW_ELEMENT_HEIGHT_pixel
SOLER_WINDOW_PADDING_pixel		equ	1
