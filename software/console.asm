;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty
	;-----------------------------------------------------------------------
	%include	"software/console/config.asm"
	;-----------------------------------------------------------------------

console:
	; ; inicjalizacja przestrzeni konsoli
	%include	"software/console/init.asm"

.loop:
	; pobierz wiadomość
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	console_ipc_data
	int	KERNEL_SERVICE
	jc	.loop	; brak wiadomości

	; otrzymano klawisz od klawiatury?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.data + SERVICE_DESU_STRUCTURE_IPC.type],	SERVICE_DESU_IPC_KEYBOARD
	jne	.loop	; nie, zignoruj komunikat

	; pobierz kod ASCII klawisza
	mov	rax,	qword [rdi + KERNEL_IPC_STRUCTURE.data + SERVICE_DESU_STRUCTURE_IPC.value0]

	; wartość ASCII klawisza możliwa do wyświetlenia?
	cmp	rax,	STATIC_ASCII_SPACE
	jb	.loop	; nie, zignoruj klawisz
	cmp	rax,	STATIC_ASCII_DELETE
	jae	.loop	; nie, zignoruj klawisz

	; wyświetl znak w polu terminala
	mov	ecx,	1	; 1 raz
	call	library_terminal_char

	; aktualizuj zawartość okna
	mov	al,	SERVICE_DESU_WINDOW_update
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	SERVICE_DESU_IRQ

	; zatrzymaj dalsze wykonywanie kodu
	jmp	.loop

	;-----------------------------------------------------------------------
	%include	"software/console/data.asm"
	;-----------------------------------------------------------------------
	%include	"library/bosu.asm"
	%include	"library/font.asm"
	%include	"library/page_from_size.asm"
	%include	"library/terminal.asm"
	;-----------------------------------------------------------------------
