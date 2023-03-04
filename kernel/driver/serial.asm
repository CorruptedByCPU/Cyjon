;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; void
driver_serial:
	; preserve original register
	push	rax
	push	rdx

	; disable interrupt generation
	mov	al,	0x00
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_register.interrupt_enable_or_divisor_high
	out	dx,	al

	; enable DLAB (frequency divider)
	mov	al,	0x80
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_register.line_control_or_dlab
	out	dx,	al

	; communication frequency: 38400
	mov	al,	0x03
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_register.data_or_divisor_low
	out	dx,	al
	mov	al,	0x00
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_register.interrupt_enable_or_divisor_high
	out	dx,	al

	; 8 bits per sign, no parity, 1 stop bit
	mov	al,	0x03
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_register.line_control_or_dlab
	out	dx,	al

	; enable FIFO, clear with 14 byte threshold
	mov	al,	0xC7
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_register.interrupt_identification_or_fifo
	out	dx,	al

	; set RTS/DSR, AUX1, AUX2
	mov	al,	0x0B
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_register.modem_control
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
	call	driver_serial_ready

	; output port number
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_register.data_or_divisor_low

	; send character
	out	dx,	al

	; restore original register
	pop	rdx

	; return from routine
	ret


;-------------------------------------------------------------------------------
; void
driver_serial_ready:
	; preserve original registers
	push	rax
	push	rdx

	; line status port
	mov	dx,	DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_register.line_status

.loop:
	; retrieve controller status
	in	al,	dx

	; cache empty?
	test	al,	01100000b
	jz	.loop	; no, wait longer

	; regoster original registers
	pop	rdx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - length of string in Bytes
;	rsi - pointer to string
driver_serial_string:
	; preserve original register
	push	rax
	push	rcx
	push	rsi

	; empty string?
	test	rcx,	rcx
	jz	.end	; yes

.loop:
	; load character from string
	lodsb

	; send character to output
	call	driver_serial_char

	; show other characters from string
	dec	rcx
	jnz	.loop

.end:
	; restore original registers
	pop	rsi
	pop	rcx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rax - value
;	rbx - number base
;	rcx - prefix length
;	dl  - TRUE/FALSE signed value?
driver_serial_value:
	; preserve original registers
	push	rax
	push	rbp
	push	rdx
	push	rcx

	; stack of separated digits
	mov	rbp,	rsp

	; value length in digits
	xor	ecx,	ecx

.loop:
	; division result
	xor	edx,	edx

	; modulo
	div	rbx

	; convert digit to ASCII
	add	dl,	STATIC_ASCII_DIGIT_0
	push	rdx	; and keep on stack

	; first digit
	inc	rcx

	; keep parsing?
	test	rax,	rax
	jnz	.loop	; yes

.prefix:
	; prefix with correct length?
	cmp	rcx,	qword [rbp]
	jae	.sign	; yes

	; add ZERO
	push	STATIC_ASCII_DIGIT_0

	; next digit
	inc	rcx
	jmp	.prefix

.sign:
	; value should be signed?
	test	qword [rbp + 0x08],	EMPTY
	je	.print	; no

	; show sign
	push	STATIC_ASCII_MINUS

.print:
	; show all digits

	; something left?
	cmp	rsp,	rbp
	je	.end	; no

	; get a digit
	pop	rax

	; is base of digit is greater than 10
	cmp	al,	STATIC_ASCII_DIGIT_0 + 10
	jb	.no	; no

	; correct ASCII code to base number
	add	al,	0x07

.no:
	; show digit
	call	driver_serial_char

	; next digit
	jmp	.print

.end:
	; restore original registers
	pop	rcx
	pop	rdx
	pop	rbp
	pop	rax

	; return from routine
	ret