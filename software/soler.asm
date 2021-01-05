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

	; test
	xchg	bx,bx

	; przelicz 8/7
	finit
	fild	dword [a]	; mov	st1,	dword [a]
	fild	dword [b]	; mov	st0,	dword [b]
	fdivp	st1	; div	st0
			; mov	st0,	st1
	fstp	qword [result]	; zapisz

	finit	; reset koprocesora
        fstcw	word [control]	; zapisz flagi koprocesora
	mov	ax,	110000000000b	; nie zachowuj wartości za przecinkiem
	or	word [control],	ax
        fldcw	word [control]	; wczytaj nowe flagi koprocesora
        fld	qword [result]	; mov	st0,	qword [result]
        fist	dword [integer]	; mov	dword [integer],	st0

	finit	; reset koprocesora
        fld	qword [result]	; mov	st1,	qword [result]
        fild	dword [integer]	; mov	st0,	dword [integer]
        fsub	; sub	st1,	st0
		; mov	st0,	st1
        fstp	qword [temp]	; mov	qword [temp],	st0

	finit	; reset koprocesora
        fld	qword [temp]	; mov	st1,	qword [temp]
        fild	dword [precision]	; mov	st0,	dword [precision]
        fmul	; mul	st1
	fistp	qword [decimal]	; mov	qword [decimal],	st0

	mov	eax,	dword [integer]	; 1
	mov	rbx,	qword [decimal]	; 14

	jmp	soler

align	4

a		dq	8
b		dq	7
result		dq	0.0

control		dw	0
integer		dd	0
decimal		dq	0
precision	dq	100	; do 2 miejsc po przecinku
temp		dq	0.0

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
