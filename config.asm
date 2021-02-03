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
SOFTWARE_BASE_address					equ	0x0000200000000000
SOFTWARE_BASE_stack_pointer				equ	0x0000800000000000

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

STATIC_MOVE_AL_HALF_TO_LOW_shift			equ	4	; 11110000b => 00001111b
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
STATIC_DQWORD_SIZE_byte					equ	0x10
STATIC_QWORD_SIZE_bit					equ	64

STATIC_WORD_mask					equ	0x000000000000FFFF
STATIC_DWORD_mask					equ	0x00000000FFFFFFFF
STATIC_QWORD_mask					equ	0xFFFFFFFF00000000

STATIC_BYTE_BIT_sign					equ	7
STATIC_WORD_BIT_sign					equ	15
STATIC_DWORD_BIT_sign					equ	31
STATIC_QWORD_BIT_sign					equ	63

STATIC_QWORD_DIGIT_length				equ	16

STATIC_SCANCODE_RELEASE_mask				equ	0x80
STATIC_SCANCODE_TERMINATOR				equ	0x00
STATIC_SCANCODE_BACKSPACE				equ	0x08
STATIC_SCANCODE_TAB					equ	0x09
STATIC_SCANCODE_NEW_LINE				equ	0x0A
STATIC_SCANCODE_RETURN					equ	0x0D
STATIC_SCANCODE_ESCAPE					equ	0x1B
STATIC_SCANCODE_CTRL_LEFT				equ	0x1D
STATIC_SCANCODE_SPACE					equ	0x20
STATIC_SCANCODE_ASTERISK				equ	0x2A
STATIC_SCANCODE_MINUS					equ	0x2D
STATIC_SCANCODE_DOT					equ	0x2E
STATIC_SCANCODE_SLASH					equ	0x2F
STATIC_SCANCODE_DIGIT_0					equ	0x30
STATIC_SCANCODE_DIGIT_1					equ	0x31
STATIC_SCANCODE_DIGIT_2					equ	0x32
STATIC_SCANCODE_DIGIT_3					equ	0x33
STATIC_SCANCODE_DIGIT_4					equ	0x34
STATIC_SCANCODE_DIGIT_5					equ	0x35
STATIC_SCANCODE_DIGIT_6					equ	0x36
STATIC_SCANCODE_DIGIT_7					equ	0x37
STATIC_SCANCODE_DIGIT_8					equ	0x38
STATIC_SCANCODE_DIGIT_9					equ	0x39
STATIC_SCANCODE_COLON					equ	0x3A
STATIC_SCANCODE_HIGH_CASE				equ	0x41
STATIC_SCANCODE_BACKSLASH				equ	0x5C
STATIC_SCANCODE_CARET					equ	0x5E
STATIC_SCANCODE_LOW_CASE				equ	0x61
STATIC_SCANCODE_TILDE					equ	0x7E
STATIC_SCANCODE_NUMLOCK_OFF_ENTER			equ	0xE01C
STATIC_SCANCODE_NUMLOCK_DIVISION			equ	0xE035
STATIC_SCANCODE_NUMLOCK_MULTIPLY			equ	0xE037
STATIC_SCANCODE_ALT_LEFT				equ	0xE038
STATIC_SCANCODE_HOME					equ	0xE047
STATIC_SCANCODE_UP					equ	0xE048
STATIC_SCANCODE_PAGE_UP					equ	0xE049
STATIC_SCANCODE_NUMLOCK_MINUS				equ	0xE04A
STATIC_SCANCODE_LEFT					equ	0xE04B
STATIC_SCANCODE_NUMLOCK_5				equ	0xE04C
STATIC_SCANCODE_RIGHT					equ	0xE04D
STATIC_SCANCODE_NUMLOCK_ADD				equ	0xE04E
STATIC_SCANCODE_END					equ	0xE04F
STATIC_SCANCODE_DOWN					equ	0xE050
STATIC_SCANCODE_PAGE_DOWN				equ	0xE051
STATIC_SCANCODE_INSERT					equ	0xE052
STATIC_SCANCODE_DELETE					equ	0xE053
STATIC_SCANCODE_SHIFT_LEFT				equ	0xE0AA
STATIC_SCANCODE_SHIFT_RIGHT				equ	0xE0B6
STATIC_SCANCODE_NUMLOCK_4				equ	0xE14B
STATIC_SCANCODE_NUMLOCK_6				equ	0xE14D
STATIC_SCANCODE_NUMLOCK_2				equ	0xE14F
STATIC_SCANCODE_NUMLOCK_3				equ	0xE150
STATIC_SCANCODE_NUMLOCK_0				equ	0xE151
STATIC_SCANCODE_NUMLOCK_DOT				equ	0xE152

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

STATIC_SEQUENCE_length_min				equ	0x05

%define STATIC_SEQUENCE_CLEAR					"^[t0]"	; wyczyść przestrzeń konsoli/terminala
%define STATIC_SEQUENCE_CURSOR					"^[t1;__--]"	; ustaw kursor na pozycji xxxx(16),yyyy(16)
%define	STATIC_SEQUENCE_CURSOR_ENABLE				"^[t2;0]"	; włącz kursor tekstowy
%define	STATIC_SEQUENCE_CURSOR_DISABLE				"^[t2;1]"	; wyłącz kursor tekstowy
%define	STATIC_SEQUENCE_CURSOR_PUSH				"^[t2;2]"	; zapamiętaj pozycję
%define	STATIC_SEQUENCE_CURSOR_POP				"^[t2;3]"	; przywróć pozycję
%define	STATIC_SEQUENCE_CURSOR_RESET				"^[t2;4]"	; resetuj blokadę kursora (wymuś pokazanie kursora)
%define	STATIC_SEQUENCE_CURSOR_UP				"^[t2;C]"	; przesuń kursor o pozycję w górę
%define	STATIC_SEQUENCE_CURSOR_DOWN				"^[t2;D]"	; przesuń kursor o pozycję w dół
%define	STATIC_SEQUENCE_CURSOR_LEFT				"^[t2;E]"	; przesuń kursor o pozycję w lewo
%define	STATIC_SEQUENCE_CURSOR_RIGHT				"^[t2;F]"	; przesuń kursor o pozycję w prawo
%define	STATIC_SEQUENCE_CLEAR_LINE				"^[t3]"		; wyczyść aktualną linię
%define	STATIC_SEQUENCE_SCROOL_UP				"^[t4;__--]"	; przewiń zawartość terminala o "__" linii w górę, zaczynając od linii "--"
%define	STATIC_SEQUENCE_SCROOL_DOWN				"^[t5;__--]"	; przewiń zawartość terminala o "__" linii w dół, zaczynając od linii "--"
%define	STATIC_SEQUENCE_NUMBER					"^[t6;-=~________]"	; wyświetl wartość "________" o podstawie "-" z prefiksem rozmiaru "=" i wartości "~"
%define	STATIC_SEQUENCE_COLOR_DEFAULT				"^[c07]"	; kolor jasno-szary na czarnym tle
%define	STATIC_SEQUENCE_COLOR_BLACK				"^[c*0]"
%define	STATIC_SEQUENCE_COLOR_RED				"^[c*1]"
%define	STATIC_SEQUENCE_COLOR_GREEN				"^[c*2]"
%define	STATIC_SEQUENCE_COLOR_BROWN				"^[c*3]"
%define	STATIC_SEQUENCE_COLOR_BLUE				"^[c*4]"
%define	STATIC_SEQUENCE_COLOR_MAGENTA				"^[c*5]"
%define	STATIC_SEQUENCE_COLOR_CYAN				"^[c*6]"
%define	STATIC_SEQUENCE_COLOR_GRAY_LIGHT			"^[c*7]"
%define	STATIC_SEQUENCE_COLOR_GRAY				"^[c*8]"
%define	STATIC_SEQUENCE_COLOR_RED_LIGHT				"^[c*9]"
%define	STATIC_SEQUENCE_COLOR_GREEN_LIGHT			"^[c*A]"
%define	STATIC_SEQUENCE_COLOR_YELLOW				"^[c*B]"
%define	STATIC_SEQUENCE_COLOR_BLUE_LIGHT			"^[c*C]"
%define	STATIC_SEQUENCE_COLOR_MAGENTA_LIGHT			"^[c*D]"
%define	STATIC_SEQUENCE_COLOR_CYAN_LIGHT			"^[c*E]"
%define	STATIC_SEQUENCE_COLOR_WHITE				"^[c*F]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_BLACK			"^[c0*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_RED			"^[c1*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_GREEN			"^[c2*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_BROWN			"^[c3*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_BLUE			"^[c4*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_MAGENTA		"^[c5*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_CYAN			"^[c6*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_GRAY_LIGHT		"^[c7*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_GRAY			"^[c8*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_RED_LIGHT		"^[c9*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_GREEN_LIGHT		"^[cA*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_YELLOW			"^[cB*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_BLUE_LIGHT		"^[cC*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_MAGENTA_LIGHT		"^[cD*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_CYAN_LIGHT		"^[cE*]"
%define	STATIC_SEQUENCE_COLOR_BACKGROUND_WHITE			"^[cF*]"

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
STATIC_COLOR_gray					equ	0x00555555
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
