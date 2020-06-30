;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

%define	KERNEL_name					"Cyjon"
%define	KERNEL_version					"0"
%define	KERNEL_revision					"1215"
%define	KERNEL_architecture				"x86_64"

KERNEL_BASE_address					equ	0x0000000000100000

KERNEL_STACK_address					equ	KERNEL_MEMORY_HIGH_VIRTUAL_address - KERNEL_STACK_SIZE_byte
KERNEL_STACK_pointer					equ	KERNEL_MEMORY_HIGH_VIRTUAL_address - KERNEL_PAGE_SIZE_byte
KERNEL_STACK_SIZE_byte					equ	KERNEL_PAGE_SIZE_byte * 0x02	; 4 KiB dla stosu/kontekstu, 4 KiB dla SSE,MMX,AVX
KERNEL_STACK_TEMPORARY_pointer				equ	0x7000 + KERNEL_PAGE_SIZE_byte

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
; SERVICE
;===============================================================================
KERNEL_SERVICE						equ	0x40

KERNEL_SERVICE_PROCESS					equ	0x0000
KERNEL_SERVICE_PROCESS_exit				equ	0x0000 + KERNEL_SERVICE_PROCESS
KERNEL_SERVICE_PROCESS_run				equ	0x0100 + KERNEL_SERVICE_PROCESS
KERNEL_SERVICE_PROCESS_check				equ	0x0200 + KERNEL_SERVICE_PROCESS
KERNEL_SERVICE_PROCESS_memory_alloc			equ	0x0300 + KERNEL_SERVICE_PROCESS
KERNEL_SERVICE_PROCESS_ipc_receive			equ	0x0400 + KERNEL_SERVICE_PROCESS
KERNEL_SERVICE_PROCESS_pid				equ	0x0500 + KERNEL_SERVICE_PROCESS

KERNEL_SERVICE_VIDEO					equ	0x0001
KERNEL_SERVICE_VIDEO_properties				equ	0x0000 + KERNEL_SERVICE_VIDEO

KERNEL_SERVICE_VFS					equ	0x0003
KERNEL_SERVICE_VFS_exist				equ	0x0000 + KERNEL_SERVICE_VFS

KERNEL_SERVICE_SYSTEM					equ	0x0004
KERNEL_SERVICE_SYSTEM_memory				equ	0x0000 + KERNEL_SERVICE_SYSTEM

;===============================================================================
; IPC
;===============================================================================
struc	KERNEL_IPC_STRUCTURE
	.ttl			resb	8
	.pid_source		resb	8
	.pid_destination	resb	8
	.data:
	.size			resb	8
	.pointer		resb	8
	.other			resb	24
	.SIZE:
endstruc

;===============================================================================
; ERROR
;===============================================================================
KERNEL_ERROR_memory_low					equ	0x0001

;===============================================================================
; DESU
;===============================================================================
SERVICE_DESU_IPC_KEYBOARD				equ	0
SERVICE_DESU_IPC_MOUSE_BUTTON_LEFT_press		equ	1
SERVICE_DESU_IPC_MOUSE_BUTTON_RIGHT_press		equ	2

struc	SERVICE_DESU_STRUCTURE_IPC
	.type						resb	1
	.reserved					resb	7
	.id						resb	8
	.value0						resb	8
	.value1						resb	8
endstruc
