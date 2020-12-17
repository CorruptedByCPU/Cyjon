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
	%include	"kernel/header/stream.inc"
	%include	"kernel/header/service.inc"
	%include	"kernel/header/vfs.inc"
	%include	"kernel/header/ipc.inc"
	%include	"kernel/header/wm.inc"
	%include	"kernel/macro/debug.asm"
	;-----------------------------------------------------------------------
	%include	"software/moko/config.asm"
	%include	"software/console/header.inc"
	;-----------------------------------------------------------------------

	; r8d	- szerokość przestrzeni dokumentu w znakach liczona od zera
	; r9d	- wysokość przestrzeni dokumentu w znakach liczona od zera
	; r10	- wskaźnik pozycji kursora w przestrzeni dokumentu
	; r11	- przesunięcie wew. linii
	; r12	- numer znaku (liczony od zera) od którego rozpocząć wyświetlanie linii
	; r13	- rozmiar linii w znakach
	; r14	- pozycja kursora na osi X
	; r15	- pozycja kursora na osi Y

; 64 bitowy kod programu
[bits 64]

; adresowanie względne
[default rel]

; położenie kodu programu w pamięci logicznej
[org SOFTWARE_base_address]

;===============================================================================
moko:
	; inicjalizuj środowisko pracy edytora tekstu
	%include	"software/moko/init.asm"

.loop:
	; pobierz komunikat "znak z bufora klawiatury"
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	moko_ipc_data
	int	KERNEL_SERVICE
	jc	.loop	; brak komunikatu

	; komunikat typu: klawiatura?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	jne	.loop	; zignoruj

	; pobierz kod klawisza
	mov	ax,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value0]

	; wywołano skrót klawiszowy?
	call	moko_shortcut
	jnc	.loop	; tak

	; klawisz funkcyjny?
	call	moko_key
	jnc	.loop	; tak

	; znak drukowalny?
	cmp	ax,	STATIC_SCANCODE_SPACE
	jb	.loop	; nie
	cmp	ax,	STATIC_SCANCODE_TILDE
	ja	.loop	; tak

	; wstaw znak do dokumentu
	xor	bl,	bl	; aktualizuj wszystkie zmienne globalne
	call	moko_document_insert

	; wyświetl ponownie zawartość aktualnej linii na ekran
	call	moko_line

	; powrót do pętli głównej
	jmp	.loop

.end:
	; przesuń kursor na koniec przestrzeni znakowej
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_close_end - moko_string_close
	mov	rsi,	moko_string_close
	int	KERNEL_SERVICE

	; zakończ działanie programu
	xor	ax,	ax
	int	KERNEL_SERVICE

	; debug
	macro_debug	"software: moko"

	;-----------------------------------------------------------------------
	%include	"software/moko/data.asm"
	%include	"software/moko/document.asm"
	%include	"software/moko/interface.asm"
	%include	"software/moko/key.asm"
	%include	"software/moko/line.asm"
	%include	"software/moko/shortcut.asm"
	;-----------------------------------------------------------------------
