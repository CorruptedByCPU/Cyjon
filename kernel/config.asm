;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

%define	KERNEL_name					"Cyjon"
%define	KERNEL_version					"0"
%define	KERNEL_revision					"1258"
%define	KERNEL_architecture				"x86_64"

KERNEL_BASE_address					equ	0x0000000000100000

KERNEL_STACK_address					equ	KERNEL_MEMORY_HIGH_VIRTUAL_address - KERNEL_STACK_SIZE_byte
KERNEL_STACK_pointer					equ	KERNEL_MEMORY_HIGH_VIRTUAL_address - STATIC_PAGE_SIZE_byte
KERNEL_STACK_SIZE_byte					equ	STATIC_PAGE_SIZE_byte * 0x02	; 4 KiB dla stosu/kontekstu, 4 KiB dla SSE,MMX,AVX
KERNEL_STACK_TEMPORARY_pointer				equ	0x7000 + STATIC_PAGE_SIZE_byte

;===============================================================================
; MEMORY
;===============================================================================
KERNEL_MEMORY_HIGH_mask					equ	0xFFFF000000000000
KERNEL_MEMORY_HIGH_REAL_address				equ	0xFFFF800000000000
KERNEL_MEMORY_HIGH_VIRTUAL_address			equ	KERNEL_MEMORY_HIGH_REAL_address - KERNEL_MEMORY_HIGH_mask

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

;===============================================================================
; WM
;===============================================================================
KERNEL_WM_IRQ						equ	0x41

KERNEL_WM_WINDOW_close					equ	0x00
KERNEL_WM_WINDOW_create					equ	0x01
KERNEL_WM_WINDOW_update					equ	0x02

KERNEL_WM_IPC_MOUSE_btn_left_press			equ	0
KERNEL_WM_IPC_MOUSE_btn_left_release			equ	1
KERNEL_WM_IPC_MOUSE_btn_right_press			equ	2
KERNEL_WM_IPC_MOUSE_btn_right_release			equ	3

struc	KERNEL_WM_STRUCTURE_IPC
	.action						resb	1
	.reserved					resb	7
	.id						resb	8
	.value0						resb	8
	.value1						resb	8
endstruc
