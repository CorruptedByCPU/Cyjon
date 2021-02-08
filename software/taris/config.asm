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

%define	PROGRAM_NAME		"taris"
%define	PROGRAM_VERSION		"0.2"

TARIS_BRICK_START_POSITION_x	equ	6
TARIS_BRICK_START_POSITION_y	equ	0

TARIS_BRICK_STRUCTURE_width	equ	4
TARIS_BRICK_STRUCTURE_height	equ	4

TARIS_BRICK_PADDING_pixel	equ	1
TARIS_BRICK_WIDTH_pixel		equ	12
TARIS_BRICK_HEIGHT_pixel	equ	12

TARIS_PLAYGROUND_WIDTH_brick	equ	10
TARIS_PLAYGROUND_HEIGHT_brick	equ	22
TARIS_PLAYGROUND_HIDDEN_brick	equ	2

TARIS_PLAYGROUND_WIDTH_pixel	equ	TARIS_PLAYGROUND_WIDTH_brick * (TARIS_BRICK_WIDTH_pixel + TARIS_BRICK_PADDING_pixel)
TARIS_PLAYGROUND_HEIGHT_pixel	equ	(TARIS_PLAYGROUND_HEIGHT_brick - TARIS_PLAYGROUND_HIDDEN_brick) * (TARIS_BRICK_HEIGHT_pixel + TARIS_BRICK_PADDING_pixel)

TARIS_WINDOW_WIDTH_pixel	equ	TARIS_PLAYGROUND_WIDTH_pixel
TARIS_WINDOW_HEIGHT_pixel	equ	TARIS_PLAYGROUND_HEIGHT_pixel
