;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"
	%include	"config.asm"	; globalne
	;-----------------------------------------------------------------------
	%include	"software/console/config.asm"
	%include	"software/console/header.inc"
	;-----------------------------------------------------------------------

; 64 bitowy kod programu
[bits 64]

; adresowanie względne
[default rel]

; położenie kodu programu w pamięci logicznej
[org SOFTWARE_base_address]

;===============================================================================
console:
	; ; inicjalizacja przestrzeni konsoli
	%include	"software/console/init.asm"

.loop:
	; pobierz wiadomość
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	console_ipc_data
	int	KERNEL_SERVICE
	jc	.loop	; brak wiadomości

	; komunikat typu: klawiatura?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	je	.transfer	; tak

	; komunikat typu: ekran?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_GRAPHICS
	jne	.loop	; nie, zignoruj

	; zwróć szerokość i wysokość przestrzeni tekstowej w znakach
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.data + CONSOLE_STRUCTURE_IPC.width],	CONSOLE_WINDOW_WIDTH_char
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.data + CONSOLE_STRUCTURE_IPC.height],	CONSOLE_WINDOW_HEIGHT_char

	; pozycję kurosra w przestrzeni konsolie
	mov	rax,	qword [console_terminal_table + LIBRARY_TERMINAL_STRUCTURE.cursor]
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.data + CONSOLE_STRUCTURE_IPC.cursor],	rax

.transfer:
	; prześlij komunikat do powłoki
	call	console_transfer

	; pobierz znak z strumienia
	mov	ax,	KERNEL_SERVICE_PROCESS_in
	mov	rdi,	qword [console_cache_address]
	int	KERNEL_SERVICE

	;
	; ; wyświetl znak w polu terminala
	; mov	ecx,	1	; 1 raz
	; call	library_terminal_char
	;
	; ; aktualizuj zawartość okna
	; mov	al,	KERNEL_WM_WINDOW_update
	; or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	; int	KERNEL_WM_IRQ

	; zatrzymaj dalsze wykonywanie kodu
	jmp	.loop

	;-----------------------------------------------------------------------
	%include	"software/console/data.asm"
	%include	"software/console/transfer.asm"
	;-----------------------------------------------------------------------
	%include	"library/bosu.asm"
	%include	"library/font.asm"
	%include	"library/page_from_size.asm"
	%include	"library/terminal.asm"
	;-----------------------------------------------------------------------
