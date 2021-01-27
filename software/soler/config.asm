;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"software/header.asm"
	;-----------------------------------------------------------------------

%define	PROGRAM_NAME			"soler"
%define	PROGRAM_VERSION			"0.3"

SOLER_WINDOW_PADDING_pixel		equ	0x01
SOLER_WINDOW_WIDTH_pixel		equ	SOLER_WINDOW_ELEMENT_MARGIN_pixel + (SOLER_WINDOW_ELEMENT_AREA_pixel * SOLER_WINDOW_WIDTH_element)
SOLER_WINDOW_HEIGHT_pixel		equ	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + (SOLER_WINDOW_ELEMENT_AREA_pixel * SOLER_WINDOW_HEIGHT_element)

SOLER_WINDOW_ELEMENT_MARGIN_pixel	equ	0x01
SOLER_WINDOW_ELEMENT_SIZE_pixel		equ	0x10
SOLER_WINDOW_ELEMENT_AREA_pixel		equ	SOLER_WINDOW_ELEMENT_SIZE_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel

SOLER_WINDOW_WIDTH_element		equ	0x04
SOLER_WINDOW_HEIGHT_element		equ	0x05

SOLER_INPUT_HEIGHT_pixel		equ	12
SOLER_INPUT_VALUE_WIDTH_char		equ	(SOLER_WINDOW_WIDTH_pixel / LIBRARY_FONT_WIDTH_pixel) - SOLER_INPUT_OPERATION_WIDTH_char
SOLER_INPUT_VALUE_WIDTH_pixel		equ	(SOLER_WINDOW_WIDTH_pixel - SOLER_INPUT_OPERATION_WIDTH_pixel) - (SOLER_WINDOW_PADDING_pixel << STATIC_MULTIPLE_BY_2_shift)
SOLER_INPUT_OPERATION_WIDTH_char	equ	1
SOLER_INPUT_OPERATION_WIDTH_pixel	equ	SOLER_INPUT_OPERATION_WIDTH_char * LIBRARY_FONT_WIDTH_pixel
