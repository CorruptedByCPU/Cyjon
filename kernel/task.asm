;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

kernel_task_address			dq	STATIC_EMPTY

kernel_task_pid_semaphore		db	STATIC_FALSE
kernel_task_pid				dq	STATIC_EMPTY

KERNEL_TASK_EFLAGS_if			equ	000000000000001000000000b
KERNEL_TASK_EFLAGS_zf			equ	000000000000000001000000b
KERNEL_TASK_EFLAGS_cf			equ	000000000000000000000001b
KERNEL_TASK_EFLAGS_df			equ	000000000000010000000000b
KERNEL_TASK_EFLAGS_default		equ	KERNEL_TASK_EFLAGS_if

KERNEL_TASK_FLAG_active			equ	0000000000000001b
KERNEL_TASK_FLAG_closed			equ	0000000000000010b
KERNEL_TASK_FLAG_daemon			equ	0000000000000100b
KERNEL_TASK_FLAG_processing		equ	0000000000001000b
KERNEL_TASK_FLAG_secured		equ	0000000000010000b
KERNEL_TASK_FLAG_thread			equ	0000000000100000b

KERNEL_TASK_FLAG_active_bit		equ	0
KERNEL_TASK_FLAG_closed_bit		equ	1
KERNEL_TASK_FLAG_daemon_bit		equ	2
KERNEL_TASK_FLAG_processing_bit		equ	3
KERNEL_TASK_FLAG_secured_bit		equ	4
KERNEL_TASK_FLAG_thread_bit		equ	5

KERNEL_TASK_STACK_address		equ	(KERNEL_MEMORY_HIGH_VIRTUAL_address << STATIC_MULTIPLE_BY_2_shift) - KERNEL_TASK_STACK_SIZE_byte
KERNEL_TASK_STACK_SIZE_byte		equ	KERNEL_PAGE_SIZE_byte

struc	KERNEL_STRUCTURE_TASK
	.cr3				resb	8	; adres tablicy PML4 procesu
	.rsp				resb	8	; ostatni znany wskaźnik szczytu stosu kontekstu procesu
	.pid				resb	8	; unikalny identyfikator procesu
	.cpu				resb	1	; identyfikator procesora logicznego, obsługującego w danym czasie proces
	.time				resb	8	; czas uruchomienia procesu względem czasu życia jądra systemu
	.flags				resb	2	; flagi stanu procesu
	.SIZE:
endstruc

struc	KERNEL_STRUCTURE_TASK_IRETQ
	.rip						resb	8
	.cs						resb	8
	.eflags						resb	8
	.rsp						resb	8
	.ds						resb	8
endstruc
