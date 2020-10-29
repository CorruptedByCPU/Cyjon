;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; DEBUG
;===============================================================================
%define	DEBUG

;===============================================================================
; PAGE
;===============================================================================
STATIC_PAGE_mask					equ	0xF000

STATIC_PAGE_SIZE_byte					equ	0x1000
STATIC_PAGE_SIZE_shift					equ	12

;===============================================================================
; SOFTWARE
;===============================================================================
SOFTWARE_base_address					equ	KERNEL_MEMORY_HIGH_REAL_address

;===============================================================================
; STAŁE OGÓLNEGO PRZEZNACZENIA
;===============================================================================
STATIC_REPLACE_AL_WITH_HIGH_shift			equ	8
STATIC_REPLACE_AX_WITH_HIGH_shift			equ	16
STATIC_REPLACE_EAX_WITH_HIGH_shift			equ	32

STATIC_MULTIPLE_BY_2_shift				equ	1
STATIC_MULTIPLE_BY_4_shift				equ	2
STATIC_MULTIPLE_BY_8_shift				equ	3
STATIC_MULTIPLE_BY_QWORD_shift				equ	STATIC_MULTIPLE_BY_8_shift
STATIC_MULTIPLE_BY_16_shift				equ	4
STATIC_MULTIPLE_BY_32_shift				equ	5
STATIC_MULTIPLE_BY_64_shift				equ	6
STATIC_MULTIPLE_BY_512_shift				equ	9
STATIC_MULTIPLE_BY_1024_shift				equ	10
STATIC_MULTIPLE_BY_PAGE_shift				equ	STATIC_PAGE_SIZE_shift

STATIC_DIVIDE_BY_2_shift				equ	1
STATIC_DIVIDE_BY_4_shift				equ	2
STATIC_DIVIDE_BY_DWORD_shift				equ	STATIC_DIVIDE_BY_4_shift
STATIC_DIVIDE_BY_8_shift				equ	3
STATIC_DIVIDE_BY_QWORD_shift				equ	STATIC_DIVIDE_BY_8_shift
STATIC_DIVIDE_BY_16_shift				equ	4
STATIC_DIVIDE_BY_32_shift				equ	5
STATIC_DIVIDE_BY_256_shift				equ	8
STATIC_DIVIDE_BY_1024_shift				equ	10
STATIC_DIVIDE_BY_PAGE_shift				equ	STATIC_PAGE_SIZE_shift

STATIC_MOVE_AL_HALF_TO_HIGH_shift			equ	4	; 00001111b => 11110000b
STATIC_MOVE_AL_TO_HIGH_shift				equ	8
STATIC_MOVE_AX_TO_HIGH_shift				equ	16
STATIC_MOVE_EAX_TO_HIGH_shift				equ	32
STATIC_MOVE_HIGH_TO_AL_shift				equ	8
STATIC_MOVE_HIGH_TO_AX_shift				equ	16
STATIC_MOVE_HIGH_TO_EAX_shift				equ	32

STATIC_BYTE_mask					equ	0xFF
STATIC_BYTE_LOW_mask					equ	0x0F
STATIC_BYTE_HIGH_mask					equ	0xF0

STATIC_BYTE_SIZE_byte					equ	0x01
STATIC_WORD_SIZE_byte					equ	0x02
STATIC_DWORD_SIZE_byte					equ	0x04
STATIC_QWORD_SIZE_byte					equ	0x08
STATIC_QWORD_SIZE_bit					equ	64

STATIC_WORD_mask					equ	0x000000000000FFFF
STATIC_QWORD_mask					equ	0xFFFFFFFF00000000

STATIC_BYTE_BIT_sign					equ	7
STATIC_WORD_BIT_sign					equ	15
STATIC_QWORD_BIT_sign					equ	63

STATIC_QWORD_DIGIT_length				equ	16

STATIC_ASCII_TERMINATOR					equ	0x00
STATIC_ASCII_BACKSPACE					equ	0x08
STATIC_ASCII_TAB					equ	0x09
STATIC_ASCII_NEW_LINE					equ	0x0A
STATIC_ASCII_RETURN					equ	0x0D
STATIC_ASCII_ESCAPE					equ	0x1B
STATIC_ASCII_SPACE					equ	0x20
STATIC_ASCII_ASTERISK					equ	0x2A
STATIC_ASCII_MINUS					equ	0x2D
STATIC_ASCII_DOT					equ	0x2E
STATIC_ASCII_SLASH					equ	0x2F
STATIC_ASCII_DIGIT_0					equ	0x30
STATIC_ASCII_DIGIT_9					equ	0x39
STATIC_ASCII_COLON					equ	0x3A
STATIC_ASCII_HIGH_CASE					equ	0x41
STATIC_ASCII_BACKSLASH					equ	0x5C
STATIC_ASCII_CARET					equ	0x5E
STATIC_ASCII_LOW_CASE					equ	0x61
STATIC_ASCII_TILDE					equ	0x7E
STATIC_ASCII_DELETE					equ	0x7F

STATIC_TRUE						equ	0x00
STATIC_FALSE						equ	0x01

STATIC_EMPTY						equ	0x00
STATIC_RESERVED						equ	STATIC_EMPTY

STATIC_NOTHING						equ	0x90	; nop instruction

STATIC_MAX_unsigned					equ	-1

STATIC_NUMBER_SYSTEM_binary				equ	0x02
STATIC_NUMBER_SYSTEM_octal				equ	0x08
STATIC_NUMBER_SYSTEM_decimal				equ	0x0A
STATIC_NUMBER_SYSTEM_hexadecimal			equ	0x10

STATIC_ASCII_SEQUENCE_length_min			equ	0x05

%define STATIC_ASCII_SEQUENCE_CLEAR				"^[t0]"	; wyczyść przestrzeń konsoli/terminala
%define STATIC_ASCII_SEQUENCE_CURSOR				"^[t1;0;0]"	; ustaw kursor na pozycji 0(x),0(y)
%define STATIC_ASCII_SEQUENCE_CURSOR_RETURN			"^[t1;0;*]"	; ustaw kursor na początek aktualnej linii
%define	STATIC_ASCII_SEQUENCE_CURSOR_ENABLE			"^[t2;0]"	; włącz kursor tekstowy
%define	STATIC_ASCII_SEQUENCE_CURSOR_DISABLE			"^[t2;1]"	; wyłącz kursor tekstowy
%define	STATIC_ASCII_SEQUENCE_CLEAR_LINE			"^[t3]"		; wyczyść aktualną linię
%define	STATIC_ASCII_SEQUENCE_COLOR_DEFAULT			"^[c07]"	; kolor jasno-szary na czarnym tle
%define	STATIC_ASCII_SEQUENCE_COLOR_BLACK			"^[c*0]"
%define	STATIC_ASCII_SEQUENCE_COLOR_RED				"^[c*1]"
%define	STATIC_ASCII_SEQUENCE_COLOR_GREEN			"^[c*2]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BROWN			"^[c*3]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BLUE			"^[c*4]"
%define	STATIC_ASCII_SEQUENCE_COLOR_MAGENTA			"^[c*5]"
%define	STATIC_ASCII_SEQUENCE_COLOR_CYAN			"^[c*6]"
%define	STATIC_ASCII_SEQUENCE_COLOR_GRAY_LIGHT			"^[c*7]"
%define	STATIC_ASCII_SEQUENCE_COLOR_GRAY			"^[c*8]"
%define	STATIC_ASCII_SEQUENCE_COLOR_RED_LIGHT			"^[c*9]"
%define	STATIC_ASCII_SEQUENCE_COLOR_GREEN_LIGHT			"^[c*A]"
%define	STATIC_ASCII_SEQUENCE_COLOR_YELLOW			"^[c*B]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BLUE_LIGHT			"^[c*C]"
%define	STATIC_ASCII_SEQUENCE_COLOR_MAGENTA_LIGHT		"^[c*D]"
%define	STATIC_ASCII_SEQUENCE_COLOR_CYAN_LIGHT			"^[c*E]"
%define	STATIC_ASCII_SEQUENCE_COLOR_WHITE			"^[c*F]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_BLACK		"^[c0*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_RED		"^[c1*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_GREEN		"^[c2*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_BROWN		"^[c3*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_BLUE		"^[c4*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_MAGENTA		"^[c5*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_CYAN		"^[c6*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_GRAY_LIGHT	"^[c7*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_GRAY		"^[c8*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_RED_LIGHT	"^[c9*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_GREEN_LIGHT	"^[cA*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_YELLOW		"^[cB*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_BLUE_LIGHT	"^[cC*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_MAGENTA_LIGHT	"^[cD*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_CYAN_LIGHT	"^[cE*]"
%define	STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_WHITE		"^[cF*]"

STATIC_COLOR_BACKGROUND_default				equ	STATIC_COLOR_black
STATIC_COLOR_default					equ	STATIC_COLOR_gray_light
STATIC_COLOR_black					equ	0x00101010
STATIC_COLOR_blue					equ	0x000000AA
STATIC_COLOR_green					equ	0x0000AA00
STATIC_COLOR_cyan					equ	0x0000AAAA
STATIC_COLOR_red					equ	0x00AA0000
STATIC_COLOR_magenta					equ	0x00AA00AA
STATIC_COLOR_brown					equ	0x00AAAA00
STATIC_COLOR_gray_light					equ	0x00AAAAAA
STATIC_COLOR_gray					equ	0x00404040
STATIC_COLOR_blue_light					equ	0x005555FF
STATIC_COLOR_green_light				equ	0x0000FF00
STATIC_COLOR_cyan_light					equ	0x0000FFFF
STATIC_COLOR_red_light					equ	0x00FF0000
STATIC_COLOR_magenta_light				equ	0x00FF00FF
STATIC_COLOR_yellow					equ	0x00FFFF00
STATIC_COLOR_white					equ	0x00FFFFFF

struc	STATIC_STRUCTURE_BLOCK
	.data						resb	STATIC_PAGE_SIZE_byte - STATIC_QWORD_SIZE_byte
	.link						resb	8
	.SIZE:
endstruc
