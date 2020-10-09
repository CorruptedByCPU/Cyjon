;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"config.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"
	%include	"kernel/header/service.inc"
	%include	"kernel/header/stream.inc"
	%include	"kernel/header/ipc.inc"
	%include	"kernel/header/wm.inc"
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

.check:
	; pobierz informacje o strumieniu wyjścia
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	mov	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_get | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_out
	mov	ecx,	CONSOLE_STRUCTURE_STREAM_META.SIZE
	mov	rdi,	tm_stream_meta
	int	KERNEL_SERVICE
	jc	.check	; brak aktualnych informacji

.loop:
	; wyświetl nagówek "Ram"
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_ram_end - tm_string_ram
	mov	rsi,	tm_string_ram
	int	KERNEL_SERVICE

	; pobierz aktualne właściwości pamięci RAM
	mov	ax,	KERNEL_SERVICE_SYSTEM_memory
	int	KERNEL_SERVICE

	; r8 - total
	; r9 - free
	; r10 - paged
	;
	; wyświetl ilość dostępnej pamięci RAM
	mov	rax,	r9
	call	tm_ram

	; pobierz wiadomość
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	tm_ipc_data
	int	KERNEL_SERVICE
	jc	.no_event	; brak wiadomości

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
	; powrót do głównej pętli
	jmp	.check

.end:
	; zakończ proces
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"tm"

	;-----------------------------------------------------------------------
	%include	"software/tm/data.asm"
	%include	"software/tm/ram.asm"
	;-----------------------------------------------------------------------
	%include	"library/integer_to_string.asm"
	%include	"library/value_to_size.asm"
	;-----------------------------------------------------------------------
