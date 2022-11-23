;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	EMPTY				0

%define	STATIC_ASCII_TERMINATOR		0x00
%define	STATIC_ASCII_NEW_LINE		0x0A

%define	STATIC_ASCII_PERCENT		0x25
%define	STATIC_ASCII_DIGIT_0		0x30
%define	STATIC_ASCII_LETTER_u		0x75

%define	STATIC_PAGE_mask		0xFFFFFFFFFFFFF000
%define	STATIC_PAGE_SIZE_page		1
%define	STATIC_PAGE_SIZE_shift		12
%define	STATIC_PAGE_SIZE_byte		4096

%define	STATIC_DIVIDE_BY_8_shift	3
%define	STATIC_DIVIDE_BY_QWORD_shift	STATIC_DIVIDE_BY_8_shift

%define	STATIC_MULTIPLE_BY_512_shift	9

%define	STATIC_PTR_SIZE_byte		8