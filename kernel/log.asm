;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

; debug, TODO remove this function
driver_serial_string:
	ret

%MACRO	KERNEL_LOG_INITIALIZE 0
	; prepare stack for arguments from variables
	sub	rsp,	0x20

	; add first 4 variables to stack
	mov	qword [rsp],	rsi
	mov	qword [rsp + 0x08],	rdx
	mov	qword [rsp + 0x10],	rcx
	mov	qword [rsp + 0x18],	r8

	; preserve original registers
	push	rbp
	lea	rbp,	[rsp + 0x08]
	push	r8
	mov	r8,	qword [rbp + 0x20]

	; add 5th variable to stack
	mov	qword [rbp + 0x20],	r9
%ENDMACRO

%MACRO	KERNEL_LOG_FINALIZE 0
	; restore original registers
	mov	qword [rbp + 0x20],	r8
	pop	r8
	pop	rbp

	; remove local variables
	add	rsp,	0x20
%ENDMACRO

;-------------------------------------------------------------------------------
; in:
;	void printf( const char *string, ... );
kernel_log:
	KERNEL_LOG_INITIALIZE

	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp

.loop:
	; retrieve character from string
	mov	al,	byte [rdi]
	inc	rdi	; next character in progress

	; end of string?
	test	al,	al
	jz	.end	; yes

	; start of sequence?
	cmp	al,	STD_ASCII_PERCENT
	jne	.unsequenced	; no

	; retrieve sequence type
	mov	al,	byte [rdi]
	inc	rdi	; next character in progress

	; decimal value?
	cmp	al,	'd'
	jne	.no_decimal

	; retrieve variable
	mov	rax,	qword [rbp]
	mov	ebx,	STD_NUMBER_SYSTEM_decimal
	mov	ecx,	1	; at least 1 digit
	xor	dl,	dl	; unsigned
	call	driver_serial_value

	; variable parsed
	add	rbp, STD_SIZE_QWORD_byte

	; continue
	jmp	.loop

.no_decimal:
	; hexadecimal value?
	cmp	al,	'x'
	jne	.no_hexadecimal

	; retrieve variable
	mov	rax,	qword [rbp]
	mov	ebx,	STD_NUMBER_SYSTEM_hexadecimal
	mov	ecx,	1	; at least 1 digit
	xor	dl,	dl	; unsigned
	call	driver_serial_value

	; variable parsed
	add	rbp, STD_SIZE_QWORD_byte

	; continue
	jmp	.loop

.no_hexadecimal:
	; string?
	cmp	al,	's'
	jne	.no_string

	; retrieve string pointer
	mov	rsi,	qword [rbp]
	call	lib_string_length
	call	driver_serial_string

	; variable parsed
	add	rbp, STD_SIZE_QWORD_byte

	; continue
	jmp	.loop

.no_string:
	; unrecognized value, show whole sequence
	push	rax
	mov	al,	STD_ASCII_PERCENT
	call	driver_serial_char
	pop	rax

.unsequenced:
	; send character to failover output
	call	driver_serial_char

	; continue with string
	jmp	.loop

.end:
	; restore original registers
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	KERNEL_LOG_FINALIZE

	; return from routine
	ret