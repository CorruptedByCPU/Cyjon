;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	STD
	%define	STD

	%define	EMPTY						0
	%define	INIT						EMPTY

	%define	FALSE						0
	%define	TRUE						1

	%define	LOCK						TRUE
	%define	UNLOCK						FALSE

	; listed alphabetically below

	%define	STD_MOVE_BYTE_half				4
	%define	STD_MOVE_BYTE					8
	%define	STD_MOVE_WORD					16
	%define	STD_MOVE_DWORD					32

	%define	STD_PAGE_byte					0x1000
	%define	STD_PAGE_mask					0xFFFFFFFFFFFFF000

	%define	STD_PTR_byte					0x08

	%define	STD_SHIFT_2					1
	%define	STD_SHIFT_4					2
	%define	STD_SHIFT_8					3
	%define	STD_SHIFT_16					4
	%define	STD_SHIFT_32					5
	%define	STD_SHIFT_64					6
	%define	STD_SHIFT_PTR					STD_SHIFT_64
	%define	STD_SHIFT_128					7
	%define	STD_SHIFT_256					8
	%define	STD_SHIFT_512					9
	%define	STD_SHIFT_1024					10
	%define	STD_SHIFT_2048					11
	%define	STD_SHIFT_4096					12
	%define	STD_SHIFT_PAGE					STD_SHIFT_4096
	%define	STD_SHIFT_65536					16

	%define	STD_SIZE_BYTE_byte				1
	%define	STD_SIZE_BYTE_bit				8
	%define	STD_SIZE_WORD_byte				2
	%define	STD_SIZE_WORD_bit				16
	%define	STD_SIZE_DWORD_byte				4
	%define	STD_SIZE_DWORD_bit				32
	%define	STD_SIZE_QWORD_byte				8
	%define	STD_SIZE_QWORD_bit				64

	%define	STD_VIDEO_DEPTH_shift				2
	%define	STD_VIDEO_DEPTH_byte				4
	%define	STD_VIDEO_DEPTH_bit				32








	; OLD

	%define STD_COLOR_DEPTH_shift		2

	%define	STD_ASCII_TERMINATOR			0x00
	%define	STD_ASCII_NEW_LINE			0x0A

	%define	STD_ASCII_TERMINATOR			EMPTY
	%define	STD_ASCII_DIFFERENCE_0_A		0x07
	%define	STD_ASCII_BACKSPACE			0x08
	%define	STD_ASCII_TAB			0x09
	%define	STD_ASCII_NEW_LINE			0x0A
	%define	STD_ASCII_RETURN			0x0D
	%define	STD_ASCII_SPACE			0x20
	%define	STD_ASCII_EXCLAMATION		0x21
	%define	STD_ASCII_QUOTATION			0x22
	%define	STD_ASCII_DOLLAR			0x24
	%define STD_ASCII_PERCENT			0x25
	%define	STD_ASCII_AMPERSAND			0x26
	%define	STD_ASCII_ASTERISK			0x2A
	%define	STD_ASCII_PLUS			0x2B
	%define	STD_ASCII_COMMA			0x2C
	%define	STD_ASCII_MINUS			0x2D
	%define	STD_ASCII_DOT			0x2E
	%define	STD_ASCII_SLASH			0x2F
	%define	STD_ASCII_DIGIT_0			0x30
	%define	STD_ASCII_DIGIT_1			0x31
	%define	STD_ASCII_DIGIT_2			0x32
	%define	STD_ASCII_DIGIT_3			0x33
	%define	STD_ASCII_DIGIT_4			0x34
	%define	STD_ASCII_DIGIT_5			0x35
	%define	STD_ASCII_DIGIT_6			0x36
	%define	STD_ASCII_DIGIT_7			0x37
	%define	STD_ASCII_DIGIT_8			0x38
	%define	STD_ASCII_DIGIT_9			0x39
	%define STD_ASCII_COLON			0x3A
	%define STD_ASCII_LOWER_THAN			0x3C
	%define	STD_ASCII_GREATER_THAN		0x3E
	%define	STD_ASCII_QUESTION_MARK		0x3F
	%define	STD_ASCII_LETTER_A			0x41
	%define	STD_ASCII_LETTER_F			0x46
	%define	STD_ASCII_LETTER_N			0x4E
	%define	STD_ASCII_LETTER_T			0x54
	%define	STD_ASCII_LETTER_Z			0x5A
	%define	STD_ASCII_BRACKET_SQUARE_OPEN	0x5B
	%define	STD_ASCII_BACKSLASH			0x5C
	%define	STD_ASCII_BRACKET_SQUARE_CLOSE	0x5D
	%define	STD_ASCII_CARET			0x5E
	%define	STD_ASCII_LETTER_a			0x61
	%define	STD_ASCII_LETTER_b			0x62
	%define	STD_ASCII_LETTER_c			0x63
	%define	STD_ASCII_LETTER_d			0x64
	%define	STD_ASCII_LETTER_f			0x66
	%define	STD_ASCII_LETTER_h			0x68
	%define	STD_ASCII_LETTER_i			0x69
	%define	STD_ASCII_LETTER_l			0x6C
	%define	STD_ASCII_LETTER_n			0x6E
	%define	STD_ASCII_LETTER_q			0x71
	%define	STD_ASCII_LETTER_r			0x72
	%define	STD_ASCII_LETTER_s			0x73
	%define	STD_ASCII_LETTER_t			0x74
	%define	STD_ASCII_LETTER_u			0x75
	%define	STD_ASCII_LETTER_x			0x78
	%define	STD_ASCII_LETTER_z			0x7A
	%define	STD_ASCII_BRACLET_OPEN		0x7B
	%define	STD_ASCII_STREAM			0x7C
	%define	STD_ASCII_BRACLET_CLOSE		0x7D
	%define	STD_ASCII_TILDE			0x7E
	%define	STD_ASCII_DELETE			0x7F

	%define	STD_PAGE_mask			0xFFFFFFFFFFFFF000
	%define	STD_PAGE_SIZE_page			1
	%define	STD_PAGE_SIZE_shift			12
	%define	STD_PAGE_SIZE_byte			4096

	%define	STD_DIVIDE_BY_2_shift		1
	%define	STD_DIVIDE_BY_4_shift		2
	%define	STD_DIVIDE_BY_8_shift		3
	%define	STD_DIVIDE_BY_32_shift		5
	%define	STD_DIVIDE_BY_QWORD_shift		STD_DIVIDE_BY_8_shift
	%define	STD_DIVIDE_BY_1024_shift		10
	%define	STD_DIVIDE_BY_4096_shift		12

	%define	STD_MOVE_AL_TO_HIGH_shift		8
	%define	STD_MOVE_AX_TO_HIGH_shift		16
	%define	STD_MOVE_EAX_TO_HIGH_shift		32
	%define	STD_MOVE_HIGH_TO_AX_shift		16
	%define	STD_MOVE_HIGH_TO_EAX_shift		32

	%define	STD_MULTIPLE_BY_2_shift		1
	%define	STD_MULTIPLE_BY_WORD_shift		STD_MULTIPLE_BY_2_shift
	%define	STD_MULTIPLE_BY_4_shift		2
	%define	STD_MULTIPLE_BY_8_shift		3
	%define	STD_MULTIPLE_BY_PTR_shift		STD_MULTIPLE_BY_8_shift
	%define	STD_MULTIPLE_BY_QWORD_shift		STD_MULTIPLE_BY_8_shift
	%define	STD_MULTIPLE_BY_16_shift		4
	%define	STD_MULTIPLE_BY_64_shift		6
	%define	STD_MULTIPLE_BY_512_shift		9

	%define	STD_WORD_SIZE_byte			2
	%define	STD_DWORD_SIZE_byte			4
	%define	STD_QWORD_SIZE_byte			8
	%define	STD_PTR_SIZE_byte			STD_QWORD_SIZE_byte

	%define	STD_QWORD_SIZE_bit			64

	%define	STD_QWORD_SIGN_bit			63

	%define	STD_NUMBER_SYSTEM_decimal		10
	%define	STD_NUMBER_SYSTEM_hexadecimal	16

	%define	STD_MAX_unsigned			-1
%endif