;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"
	%include	"kernel/header/service.inc"
	%include	"kernel/header/ipc.inc"
	%include	"kernel/header/wm.inc"
	%include	"kernel/macro/debug.asm"
	;-----------------------------------------------------------------------
	%include	"software/soler/config.asm"
	;-----------------------------------------------------------------------

; 64 bitowy kod programu
[bits 64]

; adresowanie względne
[default rel]

; położenie kodu programu w pamięci logicznej
[org SOFTWARE_base_address]

;===============================================================================
soler:
	; inicjalizacja przestrzeni konsoli
	%include	"software/soler/init.asm"

.reset:
	; zresetuj stan
	xor	r10,	r10	; pierwsza wartość
	xor	r11,	r11	; druga wartość
	xor	r12,	r12	; operacja

	; aktualizuj zawartość etykiety
	call	soler_show

.refresh:
	; aktualizuj zawartość etykiety
	mov	rsi,	soler_window.element_label
	mov	rdi,	soler_window
	call	library_bosu_element_label

	; aktualizuj zawartość okna
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	soler_window
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

.loop:
	; pobierz wiadomość
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	soler_ipc_data
	int	KERNEL_SERVICE
	jc	.loop	; brak wiadomości

	; komunikat typu: urządzenie wskazujące (myszka)?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_MOUSE
	je	.mouse	; tak

	; komunikat typu: urządzenie wskazujące (klwiatura)?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	jne	.loop	; nie, zignoruj klawizs

	; pobierz kod klawisza
	mov	ax,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value0]

.operation:
	; zrestartować wszystkie operacje?
	cmp	ax,	STATIC_SCANCODE_ESCAPE
	je	.reset	; tak

	; wykonaj operację związaną z klawiszem
	call	soler_operation

	; aktualizuj zawartość etykiety
	call	soler_show

	; powrót do procedury
	jmp	.refresh

.mouse:
	; naciśnięcie lewego klawisza myszki?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.action],	KERNEL_WM_IPC_MOUSE_btn_left_press
	jne	.loop	; nie, zignoruj wiadomość

	; pobierz współrzędne kursora
	movzx	r8d,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value0]	; x
	movzx	r9d,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value1]	; y

	; pobierz wskaźnik do elementu biorącego udział w zdarzeniu
	mov	rsi,	soler_window
	call	library_bosu_element
	jc	.loop	; nie znaleziono elementu zależnego

	; element typu "Button Close"?
	cmp	byte [rsi],	LIBRARY_BOSU_ELEMENT_TYPE_button_close
	je	.close	; tak

	; pobierz wartość elementu
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.event]

	; wykonaj operację
	jmp	.operation

.close:
	; zakończ pracę programu
	xor	ax,	ax
	int	KERNEL_SERVICE

	; debug
	macro_debug	"software: soler"

	;-----------------------------------------------------------------------
	%include	"software/soler/data.asm"
	%include	"software/soler/operation.asm"
	%include	"software/soler/show.asm"
	;-----------------------------------------------------------------------
	%include	"library/bosu.asm"
	%include	"library/font.asm"
	%include	"library/integer_to_string.asm"
	;-----------------------------------------------------------------------
