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
	; proces powłoki jest uruchomiony?
	mov	ax,	KERNEL_SERVICE_PROCESS_check
	mov	rcx,	qword [console_shell_pid]
	int	KERNEL_SERVICE
	jnc	.exist	; tak

	; zamknij okno
	mov	rsi,	console_window
	call	library_bosu_close

	; zakończ działanie konsoli
	xor	ax,	ax
	int	KERNEL_SERVICE

.exist:
	; pobierz wiadomość
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	console_ipc_data
	int	KERNEL_SERVICE
	jc	.input	; brak wiadomości

	; komunikat typu: klawiatura?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	je	.transfer	; tak

	; komunikat typu: ekran?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_GRAPHICS
	jne	.input	; nie, zignoruj

	; zwrócić właściwości terminala?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.data + CONSOLE_STRUCTURE_IPC.command],		CONSOLE_IPC_COMMAND_properties
	je	.properties	; tak

	; brak obsługi innych poleceń

	; kontynuuj
	jmp	.input

.properties:
	; zwróć szerokość i wysokość przestrzeni tekstowej w znakach
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.data + CONSOLE_STRUCTURE_IPC.width],	CONSOLE_WINDOW_WIDTH_char
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.data + CONSOLE_STRUCTURE_IPC.height],	CONSOLE_WINDOW_HEIGHT_char

	; pozycję kurosra w przestrzeni konsolie
	mov	rax,	qword [console_terminal_table + LIBRARY_TERMINAL_STRUCTURE.cursor]
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.data + CONSOLE_STRUCTURE_IPC.cursor],	rax

.transfer:
	; prześlij komunikat do powłoki
	call	console_transfer

.input:
	; pobierz ciąg z strumienia
	mov	ax,	KERNEL_SERVICE_PROCESS_in
	mov	ecx,	STATIC_EMPTY	; pobierz pierwszą linię lub całą zawartość
	mov	rdi,	qword [console_cache_address]
	int	KERNEL_SERVICE
	jz	.loop	; brak danych

	; wyświetl zawartość
	xor	eax,	eax
	mov	rsi,	rdi

.parse:
	; koniec ciągu?
	test	rcx,	rcx
	jz	.flush	; tak

	; pierwszy znak należy do sekwencji?
	cmp	byte [rsi],	STATIC_ASCII_BACKSLASH
	jne	.char	; nie

	; przetworzono sekwencje?
	call	console_sequence
	jnc	.parse	; tak

.char:
	; pobierz znak z ciągu
	lodsb

	; zachowaj licznik
	push	rcx

	; wyświetl znak
	mov	ecx,	1
	call	library_terminal_char

	; przywróć licznik
	pop	rcx

	; wyświetlić pozostałe znaki z ciągu?
	dec	rcx
	jnz	.parse	; tak

.flush:
	; aktualizuj zawartość okna
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	console_window
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

	; zatrzymaj dalsze wykonywanie kodu
	jmp	.loop

	;-----------------------------------------------------------------------
	%include	"software/console/data.asm"
	%include	"software/console/transfer.asm"
	%include	"software/console/sequence.asm"
	;-----------------------------------------------------------------------
	%include	"library/bosu.asm"
	%include	"library/font.asm"
	%include	"library/page_from_size.asm"
	%include	"library/string_compare.asm"
	%include	"library/terminal.asm"
	;-----------------------------------------------------------------------
