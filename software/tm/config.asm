;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"software/header.asm"
	;-----------------------------------------------------------------------
	%include	"software/console/header.asm"
	;-----------------------------------------------------------------------

%define	PROGRAM_NAME			"tm"
%define	PROGRAM_VERSION			"0.9"

TM_TABLE_FIRST_ROW_y		equ	0x05

TM_TABLE_CELL_cpu_x		equ	0x06
TM_TABLE_CELL_mem_x		equ	0x0B
TM_TABLE_CELL_time_x		equ	0x11
TM_TABLE_CELL_process_x		equ	0x17

TM_TABLE_CELL_pid_width		equ	0x05
TM_TABLE_CELL_cpu_width		equ	0x05
TM_TABLE_CELL_mem_width		equ	0x05
TM_TABLE_CELL_time_width	equ	0x06

TM_UPTIME_FLAG_day		equ	00000001b
TM_UPTIME_FLAG_hour		equ	00000010b
TM_UPTIME_FLAG_minute		equ	00000100b
