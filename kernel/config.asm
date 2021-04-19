;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

%define	KERNEL_name					"cyjon"
%define	KERNEL_version					"0"
%define	KERNEL_revision					"1440"
%define	KERNEL_architecture				"x86_64"

KERNEL_BASE_address					equ	0x0000000000100000

KERNEL_STACK_address					equ	KERNEL_BASE_address - KERNEL_STACK_SIZE_byte
KERNEL_STACK_pointer					equ	KERNEL_STACK_address + STATIC_PAGE_SIZE_byte
KERNEL_STACK_SIZE_byte					equ	STATIC_PAGE_SIZE_byte * 0x02	; 4 KiB dla stosu/kontekstu, 4 KiB dla SSE,MMX,AVX
KERNEL_STACK_TEMPORARY_address				equ	0x1000
KERNEL_STACK_TEMPORARY_pointer				equ	0x1000 + STATIC_PAGE_SIZE_byte

;===============================================================================
; VIDEO
;===============================================================================
KERNEL_VIDEO_DEPTH_shift				equ	2
KERNEL_VIDEO_DEPTH_byte					equ	4
KERNEL_VIDEO_DEPTH_bit					equ	32

;===============================================================================
; ERROR
;===============================================================================
KERNEL_ERROR_memory_low					equ	0x0001
KERNEL_ERROR_vfs_file_not_found				equ	0x0002
KERNEL_ERROR_vfs_file_read				equ	0x0003
KERNEL_ERROR_vfs_file_not_directory			equ	0x0004
