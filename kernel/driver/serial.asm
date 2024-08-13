;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

	;----------------------------------------------------------------------
	; variables, structures, definitions of driver
	;----------------------------------------------------------------------
	%ifndef	DRIVER_SERIAL
		%include	"./serial.inc"
	%endif

;-------------------------------------------------------------------------------
; void
driver_serial_init:
	; preserve original registers
	push	rax
	push	rdx

	; disable interrupt generation
	mov	al,	0x00
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_REGISTER_interrupt_enable_or_divisor_high
	out	dx,	al

	; enable DLAB (frequency divider)
	mov	al,	0x80
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_REGISTER_line_control_or_dlab
	out	dx,	al

	; communication frequency: 38400
	mov	al,	0x03
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_REGISTER_data_or_divisor_low
	out	dx,	al
	mov	al,	0x00
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_REGISTER_interrupt_enable_or_divisor_high
	out	dx,	al

	; 8 bits per sign, no parity, 1 stop bit
	mov	al,	0x03
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_REGISTER_line_control_or_dlab
	out	dx,	al

	; enable FIFO, clear with 14 byte threshold
	mov	al,	0xC7
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_REGISTER_interrupt_identification_or_fifo
	out	dx,	al

	; not-loopback with IRQs enabled and OUT#1 and OUT#2 bits enabled
	mov	al,	0x0F
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_REGISTER_modem_control
	out	dx,	al

	; restore original registers
	pop	rdx
	pop	rax

	; return from routine
	ret


;-------------------------------------------------------------------------------
; in:
;	al - ASCII of character
driver_serial_char:
	; preserve original register
	push	rdx

	; wait for controller to be ready
	call	driver_serial_pool

	; send character
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_REGISTER_data_or_divisor_low
	out	dx,	al

	; restore original register
	pop	rdx

	; return from routine
	ret


;-------------------------------------------------------------------------------
; void
driver_serial_pool:
	; preserve original registers
	push	rax
	push	rdx

	; line status port
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_REGISTER_line_status

.loop:
	; retrieve controller status
	in	al,	dx

	; cache empty?
	test	al,	00100000b
	jz	.loop	; no, wait longer

	; regoster original registers
	pop	rdx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rax - value
;	rbx - base
;	rcx - prefix
;	dl  - character
; out:
;	rcx - amount of digits
driver_serial_value:
	; preserve original registers
	push	rax
	push	rbp
	push	rdx
	push	rcx

	; stack of digits
	mov	rbp,	rsp

	; value length in digits
	xor	ecx,	ecx

.loop:
	; division result
	xor	edx,	edx

	; modulo
	div	rbx

	; convert digit to ASCII
	add	dl,	STD_ASCII_DIGIT_0

	; digit greater than base of 10
	cmp	dl,	STD_ASCII_DIGIT_9
	jb	.store	; no

	; correction to A..Z
	add	dl,	0x07

.store:
	; and keep on stack
	push	rdx

	; first digit
	inc	rcx

	; keep parsing?
	test	rax,	rax
	jnz	.loop	; yes

.prefix:
	; prefix with correct length?
	cmp	rcx,	qword [rbp]
	jae	.print	; yes

	; add "character"
	push	dx

	; next digit
	inc	rcx
	jmp	.prefix

.print:
	; show all digits

	; something left?
	cmp	rsp,	rbp
	je	.end	; no

	; get a digit
	pop	rax

	; show digit
	call	driver_serial_char

	; next digit
	jmp	.print

.end:
	; restore original registers
	add	rsp,	0x08	; remove RCX from stack
	pop	rdx
	pop	rbp
	pop	rax

	; return from routine
	ret