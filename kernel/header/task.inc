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

; KERNEL_TASK_STRUCTURE.SIZE % STATIC_DWORD_SIZE_byte = 0
struc	KERNEL_TASK_STRUCTURE
	.cr3				resb	8	; adres tablicy PML4 procesu
	.rsp				resb	8	; ostatni znany wskaźnik szczytu stosu kontekstu procesu
	.cpu				resb	8	; identyfikator procesora logicznego, obsługującego w danym czasie proces
	.pid				resb	8	; identyfikator procesu
	.parent				resb	8	; identyfikator procesu rodzica
	.time				resb	8	; czas uruchomienia procesu względem czasu życia jądra systemu
	.knot				resb	8	; wskaźnik do supła katalogu roboczego procesu
	.map				resb	8	; wskaźnik do przestrzeni binarnej mapy pamięci procesu
	.map_size			resb	8	; rozmiar przestrzeni binarnej mapy pamięci procesu w bitach
	.flags				resb	2	; flagi stanu procesu
	.in				resb	8	; stdin
	.out				resb	8	; stdout
	.stack				resb	2	; rozmiar przestrzeni stosu kontekstu w stronach
	.length				resb	1	; ilość znaków w nazwie procesu
	.name				resb	255	; nazwa procesu
	.SIZE:
endstruc
