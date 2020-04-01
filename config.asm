;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; DEBUG
;===============================================================================
%define	DEBUG

;===============================================================================
; PAGE
;===============================================================================
KERNEL_PAGE_mask					equ	0xF000

KERNEL_PAGE_SIZE_byte					equ	0x1000
KERNEL_PAGE_SIZE_shift					equ	12

;===============================================================================
; SOFTWARE
;===============================================================================
SOFTWARE_base_address					equ	KERNEL_MEMORY_HIGH_REAL_address

;===============================================================================
; SERVICE
;===============================================================================
SERVICE_DESU_IRQ					equ	0x41
SERVICE_DESU_WINDOW_create				equ	0x00
SERVICE_DESU_WINDOW_flags				equ	0x01

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
STATIC_MULTIPLE_BY_PAGE_shift				equ	KERNEL_PAGE_SIZE_shift

STATIC_DIVIDE_BY_2_shift				equ	1
STATIC_DIVIDE_BY_4_shift				equ	2
STATIC_DIVIDE_BY_DWORD_shift				equ	STATIC_DIVIDE_BY_4_shift
STATIC_DIVIDE_BY_8_shift				equ	3
STATIC_DIVIDE_BY_QWORD_shift				equ	STATIC_DIVIDE_BY_8_shift
STATIC_DIVIDE_BY_16_shift				equ	4
STATIC_DIVIDE_BY_32_shift				equ	5
STATIC_DIVIDE_BY_256_shift				equ	8
STATIC_DIVIDE_BY_1024_shift				equ	10
STATIC_DIVIDE_BY_PAGE_shift				equ	KERNEL_PAGE_SIZE_shift

STATIC_MOVE_AL_HALF_TO_HIGH_shift			equ	4	; 00001111b => 11110000b
STATIC_MOVE_AL_TO_HIGH_shift				equ	8
STATIC_MOVE_AX_TO_HIGH_shift				equ	16
STATIC_MOVE_EAX_TO_HIGH_shift				equ	32
STATIC_MOVE_HIGH_TO_AL_shift				equ	8
STATIC_MOVE_HIGH_TO_AX_shift				equ	16
STATIC_MOVE_HIGH_TO_EAX_shift				equ	32

STATIC_BYTE_mask					equ	0xFF
STATIC_BYTE_LOW_mask					equ	0x0F

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

STATIC_ASCII_TERMINATOR					equ	0x0000
STATIC_ASCII_BACKSPACE					equ	0x0008
STATIC_ASCII_TAB					equ	0x0009
STATIC_ASCII_NEW_LINE					equ	0x000A
STATIC_ASCII_ENTER					equ	0x000D
STATIC_ASCII_ESCAPE					equ	0x001B
STATIC_ASCII_SPACE					equ	0x0020
STATIC_ASCII_MINUS					equ	0x002D
STATIC_ASCII_DOT					equ	0x002E
STATIC_ASCII_SLASH					equ	0x002F
STATIC_ASCII_DIGIT_0					equ	0x0030
STATIC_ASCII_DIGIT_9					equ	0x0039
STATIC_ASCII_COLON					equ	0x003A
STATIC_ASCII_BACKSLASH					equ	0x005C
STATIC_ASCII_TILDE					equ	0x007E
STATIC_ASCII_DELETE					equ	0x007F

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

STATIC_ASCII_SEQUENCE_length				equ	0x06

%define	STATIC_COLOR_ASCII_DEFAULT				STATIC_COLOR_ASCII_GRAY_LIGHT
%define	STATIC_COLOR_ASCII_BLACK				"\e[30m"
%define	STATIC_COLOR_ASCII_BLUE					"\e[34m"
%define	STATIC_COLOR_ASCII_GREEN				"\e[32m"
%define	STATIC_COLOR_ASCII_CYAN					"\e[36m"
%define	STATIC_COLOR_ASCII_RED					"\e[31m"
%define	STATIC_COLOR_ASCII_MAGENTA				"\e[35m"
%define	STATIC_COLOR_ASCII_BROWN				"\e[33m"
%define	STATIC_COLOR_ASCII_GRAY_LIGHT				"\e[37m"
%define	STATIC_COLOR_ASCII_GRAY					"\e[90m"
%define	STATIC_COLOR_ASCII_BLUE_LIGHT				"\e[94m"
%define	STATIC_COLOR_ASCII_GREEN_LIGHT				"\e[92m"
%define	STATIC_COLOR_ASCII_CYAN_LIGHT				"\e[96m"
%define	STATIC_COLOR_ASCII_RED_LIGHT				"\e[91m"
%define	STATIC_COLOR_ASCII_MAGENTA_LIGHT			"\e[95m"
%define	STATIC_COLOR_ASCII_YELLOW				"\e[93m"
%define	STATIC_COLOR_ASCII_WHITE				"\e[39m"

STATIC_COLOR_BACKGROUND_default				equ	STATIC_COLOR_black
STATIC_COLOR_default					equ	STATIC_COLOR_gray_light
STATIC_COLOR_black					equ	0x00101010
STATIC_COLOR_blue					equ	0x000000AA
STATIC_COLOR_green					equ	0x0000AA00
STATIC_COLOR_cyan					equ	0x0000AAAA
STATIC_COLOR_red					equ	0x00AA0000
STATIC_COLOR_magenta					equ	0x00AA00AA
STATIC_COLOR_brown					equ	0x00AA5500
STATIC_COLOR_gray_light					equ	0x00AAAAAA
STATIC_COLOR_gray					equ	0x00555555
STATIC_COLOR_blue_light					equ	0x005555FF
STATIC_COLOR_green_light				equ	0x0055FF55
STATIC_COLOR_cyan_light					equ	0x0055FFFF
STATIC_COLOR_red_light					equ	0x00FF5555
STATIC_COLOR_magenta_light				equ	0x00FF55FF
STATIC_COLOR_yellow					equ	0x00FFFF55
STATIC_COLOR_white					equ	0x00FFFFFF

struc	STATIC_STRUCTURE_BLOCK
	.data						resb	KERNEL_PAGE_SIZE_byte - STATIC_QWORD_SIZE_byte
	.link						resb	8
	.SIZE:
endstruc
