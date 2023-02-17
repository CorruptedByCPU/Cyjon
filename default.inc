;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	FALSE					0
%define	TRUE					1

%define	LOCK					TRUE
%define	UNLOCK					FALSE

%define	EMPTY					0

%define STATIC_COLOR_DEPTH_shift		2

%define	STATIC_ASCII_TERMINATOR			0x00
%define	STATIC_ASCII_NEW_LINE			0x0A

%define	STATIC_ASCII_TERMINATOR			0x00
%define	STATIC_ASCII_SPACE			0x20
%define	STATIC_ASCII_PERCENT			0x25
%define	STATIC_ASCII_MINUS			0x2D
%define	STATIC_ASCII_DIGIT_0			0x30
%define	STATIC_ASCII_LETTER_u			0x75
%define	STATIC_ASCII_TILDE			0x7E

%define	STATIC_PAGE_mask			0xFFFFFFFFFFFFF000
%define	STATIC_PAGE_SIZE_page			1
%define	STATIC_PAGE_SIZE_shift			12
%define	STATIC_PAGE_SIZE_byte			4096

%define	STATIC_DIVIDE_BY_2_shift		1
%define	STATIC_DIVIDE_BY_4_shift		2
%define	STATIC_DIVIDE_BY_8_shift		3
%define	STATIC_DIVIDE_BY_32_shift		5
%define	STATIC_DIVIDE_BY_QWORD_shift		STATIC_DIVIDE_BY_8_shift
%define	STATIC_DIVIDE_BY_1024_shift		10
%define	STATIC_DIVIDE_BY_4096_shift		12

%define	STATIC_MOVE_AL_TO_HIGH_shift		8
%define	STATIC_MOVE_AX_TO_HIGH_shift		16
%define	STATIC_MOVE_EAX_TO_HIGH_shift		32
%define	STATIC_MOVE_HIGH_TO_AX_shift		16
%define	STATIC_MOVE_HIGH_TO_EAX_shift		32

%define	STATIC_MULTIPLE_BY_2_shift		1
%define	STATIC_MULTIPLE_BY_WORD_shift		STATIC_MULTIPLE_BY_2_shift
%define	STATIC_MULTIPLE_BY_4_shift		2
%define	STATIC_MULTIPLE_BY_8_shift		3
%define	STATIC_MULTIPLE_BY_PTR_shift		STATIC_MULTIPLE_BY_8_shift
%define	STATIC_MULTIPLE_BY_QWORD_shift		STATIC_MULTIPLE_BY_8_shift
%define	STATIC_MULTIPLE_BY_16_shift		4
%define	STATIC_MULTIPLE_BY_512_shift		9

%define	STATIC_WORD_SIZE_byte			2
%define	STATIC_DWORD_SIZE_byte			4
%define	STATIC_QWORD_SIZE_byte			8
%define	STATIC_PTR_SIZE_byte			STATIC_QWORD_SIZE_byte

%define	STATIC_QWORD_SIZE_bit			64

%define	STATIC_QWORD_SIGN_bit			63

%define	STATIC_NUMBER_SYSTEM_decimal		10
%define	STATIC_NUMBER_SYSTEM_hexadecimal	16

%define	STATIC_MAX_unsigned			-1