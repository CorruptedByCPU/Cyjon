;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_TASK_FLAG_active			equ	0000000000000001b	; oznaczenie wpisu gotowego do uruchomienia
KERNEL_TASK_FLAG_closed			equ	0000000000000010b	; oznaczenie wpisu gotowego do zamknięcia
KERNEL_TASK_FLAG_service		equ	0000000000000100b
KERNEL_TASK_FLAG_processing		equ	0000000000001000b	; oznaczenie wpisu aktualnie przerwarzanego (obsługiwanego przez jeden z procesorów)
KERNEL_TASK_FLAG_secured		equ	0000000000010000b	; oznaczenie wpisu zajętego
KERNEL_TASK_FLAG_thread			equ	0000000000100000b
KERNEL_TASK_FLAG_stream_in		equ	0000000001000000b	; strumień wejścia został przekierowany lub odziedziczony
KERNEL_TASK_FLAG_stream_out		equ	0000000010000000b	; strumień wyjścia został przekierowany lub odziedziczony
KERNEL_TASK_FLAG_sleep			equ	0000000100000000b	; proces uśpiony

KERNEL_TASK_FLAG_active_bit		equ	0
KERNEL_TASK_FLAG_closed_bit		equ	1
KERNEL_TASK_FLAG_service_bit		equ	2
KERNEL_TASK_FLAG_processing_bit		equ	3
KERNEL_TASK_FLAG_secured_bit		equ	4
KERNEL_TASK_FLAG_thread_bit		equ	5
KERNEL_TASK_FLAG_stream_in_bit		equ	6
KERNEL_TASK_FLAG_stream_out_bit		equ	7
KERNEL_TASK_FLAG_sleep_bit		equ	8

struc	KERNEL_TASK_STRUCTURE_ENTRY
	.pid				resb	8	; identyfikator procesu
	.parent				resb	8	; identyfikator procesu rodzica
	.cpu				resb	8	; identyfikator procesora logicznego, obsługującego w danym czasie proces
	.time				resb	8	; czas uruchomienia procesu względem czasu życia jądra systemu
	.apic				resb	4	; niewykorzystana ilość czasu procesora
	.memory				resb	8	; rozmiar zajętej przestrzeni pamięci RAM w stronach (bez tablic stronicowania)
	.knot				resb	8	; wskaźnik do supła katalogu roboczego procesu
	.flags				resb	2	; flagi stanu procesu
	.length				resb	1	; ilość znaków w nazwie procesu
	.name:
	.SIZE:
endstruc
