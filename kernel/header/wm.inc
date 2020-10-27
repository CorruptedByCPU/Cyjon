;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_WM_IRQ				equ	0x41

KERNEL_WM_WINDOW_close			equ	0x00
KERNEL_WM_WINDOW_create			equ	0x01
KERNEL_WM_WINDOW_update			equ	0x02

KERNEL_WM_IPC_MOUSE_btn_left_press	equ	0
KERNEL_WM_IPC_MOUSE_btn_left_release	equ	1
KERNEL_WM_IPC_MOUSE_btn_right_press	equ	2
KERNEL_WM_IPC_MOUSE_btn_right_release	equ	3

struc	KERNEL_WM_STRUCTURE_IPC
	.action				resb	1
	.reserved			resb	7
	.id				resb	8
	.value0				resb	8
	.value1				resb	8
endstruc
