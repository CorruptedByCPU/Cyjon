;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"config.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"
	%include	"kernel/header/service.inc"
	%include	"kernel/header/stream.inc"
	%include	"kernel/header/ipc.inc"
	%include	"kernel/header/wm.inc"
	%include	"kernel/header/task.inc"
	%include	"kernel/macro/debug.asm"
	;-----------------------------------------------------------------------
	%include	"software/console/header.inc"
	;-----------------------------------------------------------------------
	%include	"software/tm/config.asm"
	;-----------------------------------------------------------------------

; 64 bitowy kod programu
[bits 64]

; adresowanie względne
[default rel]

; położenie kodu programu w pamięci logicznej
[org SOFTWARE_base_address]

;===============================================================================
tm:
	; wyczyść przestrzeń znakową
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_init_end - tm_string_init
	mov	rsi,	tm_string_init
	int	KERNEL_SERVICE

	; wyświetl niezmienne elementy interfejsu
	call	tm_static

.check:
	; pobierz informacje o strumieniu wyjścia
	call	tm_stream_info

.loop:
	; ustaw kursor na pozycję "uptime"
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_uptime_position_and_color_end - tm_string_uptime_position_and_color
	mov	rsi,	tm_string_uptime_position_and_color
	int	KERNEL_SERVICE

	; pobierz aktualne zegary systemu
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; wyświetl uptime systemu
	call	tm_uptime

	; wyświetl wykorzystanie pamięci RAM
	call	tm_ram

	; wyświetl ilość i listę aktywnych procesów
	call	tm_task

	;-----------------------------------------------------------------------
	; pobierz wiadomość
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	tm_ipc_data
	int	KERNEL_SERVICE
	jc	.no_event	; brak wiadomości

	xchg	bx,bx

	; komunikat typu: klawiatura?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	jne	.no_event	; nie, zignoruj

	; naciśnięto klawisz "q"?
	cmp	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value0],	"q"
	je	.end	; tak, zakończ działanie procesu

	; naciśnięto klawisz "ESC"?
	cmp	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value0],	STATIC_ASCII_ESCAPE
	je	.end	; tak, zakończ działanie procesu

.no_event:
	; uśpij proces na 1 sekundę
	mov	ax,	KERNEL_SERVICE_PROCESS_sleep
	mov	ecx,	1
	int	KERNEL_SERVICE

	; powrót do głównej pętli
	jmp	.check

.end:
	; zakończ proces
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"tm"

	;-----------------------------------------------------------------------
	%include	"software/tm/data.asm"
	%include	"software/tm/static.asm"
	%include	"software/tm/stream.asm"
	%include	"software/tm/ram.asm"
	%include	"software/tm/uptime.asm"
	%include	"software/tm/task.asm"
	%include	"software/tm/percent.asm"
	;-----------------------------------------------------------------------
	%include	"library/integer_to_string.asm"
	%include	"library/value_to_size.asm"
	;-----------------------------------------------------------------------
