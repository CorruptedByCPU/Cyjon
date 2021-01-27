;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/console/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
console:
	; inicjalizacja przestrzeni konsoli
	%include	"software/console/init.asm"

.loop:
	; uzupełnij strumień wejścia procesu o meta dane okna
	call	console_meta

	; zwolnij pozostały czas procesora
	mov	ax,	KERNEL_SERVICE_PROCESS_release
	int	KERNEL_SERVICE

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

	; komunikat typu: urządzenie wskazujące (klawiatura)?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	je	.transfer	; tak

	; komunikat typu: urządzenie wskazujące (myszka)?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_MOUSE
	jne	.input	; nie, zignoruj wiadomość

	; naciśnięcie lewego klawisza myszki?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.action],	KERNEL_WM_IPC_MOUSE_btn_left_press
	jne	.input	; nie, zignoruj wiadomość

	; pobierz współrzędne kursora
	movzx	r8d,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value0]	; x
	movzx	r9d,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value1]	; y

	; pobierz wskaźnik do elementu biorącego udział w zdarzeniu
	mov	rsi,	console_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_element
	jc	.input	; nie znaleziono elementu zależnego

	; element posiada przypisaną procedurę obsługi akcji?
	cmp	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.event],	STATIC_EMPTY
	je	.input	; nie, koniec obsługi akcji

	; wykonaj procedurę powiązaną z elementem
	mov	rax,	.input
	push	rax	; powrót z procedury
	push	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON_CLOSE.event]	; procedura do wykonania
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

	; wyłącz kursor w terminalu
	macro_library	LIBRARY_STRUCTURE_ENTRY.terminal_cursor_disable

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
	macro_library	LIBRARY_STRUCTURE_ENTRY.terminal_char

	; przywróć licznik
	pop	rcx

.next:
	; wyświetlić pozostałe znaki z ciągu?
	dec	rcx
	jnz	.parse	; tak

.flush:
	; włącz kursor w terminalu
	macro_library	LIBRARY_STRUCTURE_ENTRY.terminal_cursor_enable

	; aktualizuj zawartość okna
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	console_window
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

	; zatrzymaj dalsze wykonywanie kodu
	jmp	.loop

	macro_debug	"software: console"

	;-----------------------------------------------------------------------
	%include	"software/console/data.asm"
	%include	"software/console/transfer.asm"
	%include	"software/console/sequence.asm"
	%include	"software/console/meta.asm"
	;-----------------------------------------------------------------------
