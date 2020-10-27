;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_GUI_WINDOW_count				equ	3	; ilość okien utworzonych przez Cero

KERNEL_GUI_WINDOW_WORKBENCH_BACKGROUND_color	equ	0x00101010

KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel		equ	18
KERNEL_GUI_WINDOW_TASKBAR_MARGIN_right		equ	0x02

struc	KERNEL_GUI_STRUCTURE_TASKBAR
	.counter				resb	8
	.list:
endstruc
