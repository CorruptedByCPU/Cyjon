;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_init_ps2:
	;=======================================================================
	; z kontrolerem myszki jest najwięcej zabawy, zarazem musi być skonfigurowany jako pierwszy
	;=======================================================================

	; opróżnij bufor kontrolera PS2
	call	driver_ps2_check_dummy_answer_or_dump

	;-----------------------------------------------------------------------
	; pobierz konfigurację kontrolera PS2
	mov	al,	DRIVER_PS2_COMMAND_CONFIGURATION_GET
	call	driver_ps2_send_command_receive_answer

	; zachowaj odpowiedź
	push	rax

	; poinformuj o chęci zwrócenia odpowiedzi
	mov	al,	DRIVER_PS2_COMMAND_CONFIGURATION_SET
	call	driver_ps2_send_command

	; włącz przerwanie i zegar na porcie 1
	bts	word [rsp],	DRIVER_PS2_CONTROLLER_CONFIGURATION_BIT_SECOND_PORT_INTERRUPT
	btr	word [rsp],	DRIVER_PS2_CONTROLLER_CONFIGURATION_BIT_SECOND_PORT_CLOCK

	; przywróć zmodyfikowaną odpowiedź
	pop	rax

	; wyślij odpowiedź
	call	driver_ps2_send_answer_or_ask_device

	;-----------------------------------------------------------------------
	; wyślij polecenie reset do urządzenia na porcie 1 (urządzenie wskazujące - myszka)
	;-----------------------------------------------------------------------
	mov	al,	DRIVER_PS2_COMMAND_PORT_SECOND_BYTE_SEND
	call	driver_ps2_send_command
	mov	al,	DRIVER_PS2_DEVICE_RESET
	call	driver_ps2_send_answer_or_ask_device

	; polecenie przetworzone poprawnie?
	call	driver_ps2_receive_answer
	cmp	al,	DRIVER_PS2_ANSWER_COMMAND_ACKNOWLEDGED
	jne	.error	; nie

	; pobierz odpowiedź od urządzenia
	call	driver_ps2_receive_answer

	; polecenie przetworzone poprawnie?
	cmp	al,	DRIVER_PS2_ANSWER_SELF_TEST_SUCCESS
	jne	.error	; nie

	;-----------------------------------------------------------------------
	; pobierz identyfikator urządzenia
	;-----------------------------------------------------------------------
	call	driver_ps2_receive_answer
	mov	byte [driver_ps2_mouse_type],	al

	;-----------------------------------------------------------------------
	; ustaw urządzenie na wartości domyślne
	;-----------------------------------------------------------------------
	mov	al,	DRIVER_PS2_COMMAND_PORT_SECOND_BYTE_SEND
	call	driver_ps2_send_command
	mov	al,	DRIVER_PS2_DEVICE_SET_DEFAULT
	call	driver_ps2_send_answer_or_ask_device
	call	driver_ps2_receive_answer

	; polecenie przetworzone poprawnie?
	cmp	al,	DRIVER_PS2_ANSWER_COMMAND_ACKNOWLEDGED
	jne	.error	; nie

	;-----------------------------------------------------------------------
	; włącz przesyłanie pakietów z urządzenia do kontrolera
	;-----------------------------------------------------------------------
	mov	al,	DRIVER_PS2_COMMAND_PORT_SECOND_BYTE_SEND
	call	driver_ps2_send_command
	mov	al,	DRIVER_PS2_DEVICE_PACKETS_ENABLE
	call	driver_ps2_send_answer_or_ask_device
	call	driver_ps2_receive_answer

	; polecenie przetworzone poprawnie?
	cmp	al,	DRIVER_PS2_ANSWER_COMMAND_ACKNOWLEDGED
	je	.done	; tak

.error:
	; zatrzymaj dalsze wykonywanie kodu inicjalizacji
	jmp	$

.done:
	;-----------------------------------------------------------------------
	; podłącz procedury obsługi myszki
	;-----------------------------------------------------------------------
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_MOUSE_IRQ_number
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	rdi,	driver_ps2_mouse
	call	kernel_idt_mount

	; ustaw wektor przerwania z tablicy IDT w kontrolerze I/O APIC
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_MOUSE_IRQ_number
	; or	ax,	KERNEL_IO_APIC_TRIGER_MODE_level
	mov	ebx,	DRIVER_PS2_MOUSE_IO_APIC_register
	call	kernel_io_apic_connect

	;-----------------------------------------------------------------------
	; podłącz procedurę obsługi klawiatury
	;-----------------------------------------------------------------------
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_KEYBOARD_IRQ_number
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	rdi,	driver_ps2_keyboard
	call	kernel_idt_mount

	; ustaw wektor przerwania z tablicy IDT w kontrolerze I/O APIC
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_KEYBOARD_IRQ_number
	mov	ebx,	DRIVER_PS2_KEYBOARD_IO_APIC_register
	call	kernel_io_apic_connect
