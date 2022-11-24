;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	FALSE					0
%define	TRUE					1

%define	LOCK					TRUE
%define	UNLOCK					FALSE

%define	EMPTY					0

%define	STATIC_ASCII_TERMINATOR			0x00
%define	STATIC_ASCII_NEW_LINE			0x0A

%define	STATIC_ASCII_PERCENT			0x25
%define	STATIC_ASCII_DIGIT_0			0x30
%define	STATIC_ASCII_LETTER_u			0x75

%define	STATIC_PAGE_mask			0xFFFFFFFFFFFFF000
%define	STATIC_PAGE_SIZE_page			1
%define	STATIC_PAGE_SIZE_shift			12
%define	STATIC_PAGE_SIZE_byte			4096

%define	STATIC_DIVIDE_BY_8_shift		3
%define	STATIC_DIVIDE_BY_QWORD_shift		STATIC_DIVIDE_BY_8_shift

%define	STATIC_MULTIPLE_BY_2_shift		1
%define	STATIC_MULTIPLE_BY_8_shift		3
%define	STATIC_MULTIPLE_BY_512_shift		9

%define	STATIC_DWORD_SIZE_byte			4
%define	STATIC_QWORD_SIZE_byte			8

%define	STATIC_DWORD_SIZE_shift			2
%define	STATIC_QWORD_SIZE_shift			3

%define	STATIC_PTR_SIZE_byte			STATIC_QWORD_SIZE_byte

%define	STATIC_NUMBER_SYSTEM_hexadecimal	0x10