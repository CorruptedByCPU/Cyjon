;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, nagłówki
	;-----------------------------------------------------------------------
	%include	"config.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"
	%include	"kernel/header/vfs.inc"
	%include	"kernel/header/service.inc"
	%include	"kernel/header/ipc.inc"
	%include	"kernel/header/stream.inc"
	%include	"kernel/header/wm.inc"
	%include	"kernel/macro/debug.asm"
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
	; uzupełnij strumień wejścia procesu o meta dane okna
	call	console_meta

	; proces powłoki jest uruchomiony?
	mov	ax,	KERNEL_SERVICE_PROCESS_check
	mov	rcx,	qword [console_shell_pid]
	int	KERNEL_SERVICE
	jnc	.exist	; tak

.close:
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

	; komunikat typu: grafika?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_MOUSE
	jne	.input	; nie, zignoruj wiadomość

	; naciśnięcie lewego klawisza myszki?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.action],	KERNEL_WM_IPC_MOUSE_btn_left_press
	jne	.input	; nie, zignoruj wiadomość

	; pobierz współrzędne kursora
	mov	r8,	qword [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value0]	; x
	mov	r9,	qword [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value1]	; y

	; pobierz wskaźnik do elementu biorącego udział w zdarzeniu
	mov	rsi,	console_window
	call	library_bosu_element
	jc	.input	; nie znaleziono elementu zależnego

	; element posiada przypisaną procedurę obsługi akcji?
	cmp	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.event],	STATIC_EMPTY
	je	.input	; nie, koniec obsługi akcji

	; wykonaj procedurę powiązaną z elementem
	mov	rax,	.input
	push	rax	; powrót z procedury
	push	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON_CLOSE.event]
	ret	; call

.transfer:
	; prześlij komunikat do powłoki
	call	console_transfer

.input:
	; pobierz ciąg z strumienia
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_in
	mov	ecx,	STATIC_EMPTY	; pobierz całą zawartość
	mov	rdi,	qword [console_cache_address]
	int	KERNEL_SERVICE
	jz	.loop	; brak danych

	; wyświetl zawartość
	xor	eax,	eax
	mov	rsi,	rdi

	; przywróć wskaźnik do struktury terminala
	mov	r8,	console_terminal_table

.parse:
	; koniec ciągu?
	test	rcx,	rcx
	jz	.flush	; tak

	; przetworzono sekwencje?
	call	console_sequence
	jnc	.parse	; tak

	; pobierz znak z ciągu
	lodsb

	; brak znaku?
	test	al,	al
	jz	.next	; tak

	; zachowaj licznik
	push	rcx

	; wyświetl znak
	mov	ecx,	1
	call	library_terminal_char

	; przywróć licznik
	pop	rcx

.next:
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

	macro_debug	"console"

	;-----------------------------------------------------------------------
	%include	"software/console/data.asm"
	%include	"software/console/transfer.asm"
	%include	"software/console/sequence.asm"
	%include	"software/console/meta.asm"
	%include	"software/console/close.asm"
	;-----------------------------------------------------------------------
	%include	"library/bosu.asm"
	%include	"library/integer_to_string.asm"
	%include	"library/font.asm"
	%include	"library/page_from_size.asm"
	%include	"library/string_compare.asm"
	%include	"library/string_to_integer.asm"
	%include	"library/string_word_next.asm"
	%include	"library/terminal.asm"
	;-----------------------------------------------------------------------
