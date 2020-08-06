;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty
	;-----------------------------------------------------------------------
	%include	"software/console/config.asm"
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

	xchg	bx,bx

	nop

.transfer:
	; prześlij komunikat do powłoki
	call	console_transfer

	; ; pobierz kod ASCII klawisza
	; mov	rax,	qword [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value0]

	; ; wartość ASCII klawisza możliwa do wyświetlenia?
	; cmp	rax,	STATIC_ASCII_SPACE
	; jb	.loop	; nie, zignoruj klawisz
	; cmp	rax,	STATIC_ASCII_DELETE
	; jae	.loop	; nie, zignoruj klawisz
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
