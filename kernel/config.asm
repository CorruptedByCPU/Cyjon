;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

%define	KERNEL_name					"cyjon"
%define	KERNEL_version					"0"
%define	KERNEL_revision					"1174"
%define	KERNEL_architecture				"x86_64"

KERNEL_BASE_address					equ	0x0000000000100000

KERNEL_STACK_address					equ	KERNEL_MEMORY_HIGH_VIRTUAL_address - KERNEL_STACK_SIZE_byte
KERNEL_STACK_pointer					equ	KERNEL_MEMORY_HIGH_VIRTUAL_address - KERNEL_PAGE_SIZE_byte
KERNEL_STACK_SIZE_byte					equ	KERNEL_PAGE_SIZE_byte * 0x02	; 4 KiB dla stosu/kontekstu, 4 KiB dla SSE,MMX,AVX
KERNEL_STACK_TEMPORARY_pointer				equ	0x8000 + KERNEL_PAGE_SIZE_byte

KERNEL_MEMORY_HIGH_mask					equ	0xFFFF000000000000
KERNEL_MEMORY_HIGH_REAL_address				equ	0xFFFF800000000000
KERNEL_MEMORY_HIGH_VIRTUAL_address			equ	KERNEL_MEMORY_HIGH_REAL_address - KERNEL_MEMORY_HIGH_mask

KERNEL_SERVICE						equ	0x40

KERNEL_SERVICE_PROCESS					equ	0x00
KERNEL_SERVICE_PROCESS_exit				equ	0x0000 + KERNEL_SERVICE_PROCESS

KERNEL_SERVICE_VIDEO					equ	0x01
KERNEL_SERVICE_VIDEO_string				equ	0x0100 + KERNEL_SERVICE_VIDEO
