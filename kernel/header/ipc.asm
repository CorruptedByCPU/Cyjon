;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_IPC_TYPE_SYSTEM			equ	0x00	; komunikat zawiera dane: system
KERNEL_IPC_TYPE_KEYBOARD		equ	0x01	; komunikat zawiera dane: klawiatury
KERNEL_IPC_TYPE_MOUSE			equ	0x02	; komunikat zawiera dane: myszka
KERNEL_IPC_TYPE_GRAPHICS		equ	0x03	; komunikat zawiera dane: ekran
KERNEL_IPC_TYPE_INTERNAL		equ	0x04	; komunikat zawiera dane: rodzic <> dziecko/wątek

KERNEL_IPC_MOUSE_EVENT_left_press	equ	0
KERNEL_IPC_MOUSE_EVENT_left_release	equ	1
KERNEL_IPC_MOUSE_EVENT_right_press	equ	2
KERNEL_IPC_MOUSE_EVENT_right_release	equ	3

struc	KERNEL_IPC_STRUCTURE
	.ttl				resb	8
	.pid_source			resb	8
	.pid_destination		resb	8
	.type				resb	1
	.reserved			resb	7
	.data:
	.size				resb	8
	.pointer			resb	8
	.other				resb	32
	.SIZE:
endstruc

struc	KERNEL_IPC_STRUCTURE_DATA_MOUSE
	.x				resb	2
	.y				resb	2
	.object_id			resb	8
	.event				resb	1
	.reserved			resb	7
endstruc
