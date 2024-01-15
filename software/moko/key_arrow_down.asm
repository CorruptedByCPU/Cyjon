;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 64 Bitowy kod programu
[BITS 64]

key_arrow_down:
	; czy numer linii jest równy z ilością linii w dokumencie?
	mov	rax,	qword [variable_document_line_start]
	add	eax,	dword [variable_cursor_position + 0x04]
	sub	eax,	VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT
	cmp	rax,	qword [variable_document_count_of_lines]
	je	.end

	push	qword [variable_line_print_start]

	mov	qword [variable_line_print_start],	VARIABLE_EMPTY
	call	update_line_on_screen

	pop	qword [variable_line_print_start]

	; czy znajdujemy się w przedostatniej linii? (lub wcześniejszej)
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	ecx,	VARIABLE_MOKO_INTERFACE_MENU_HEIGHT
	sub	ecx,	VARIABLE_DECREMENT
	mov	ebx,	dword [variable_cursor_position + 0x04]
	cmp	ebx,	ecx
	jb	.lines_available

	mov	rax,	qword [variable_cursor_indicator]
	sub	rax,	qword [variable_cursor_position_on_line]
	add	rax,	qword [variable_line_count_of_chars]
	sub	rax,	qword [variable_document_address_start]
	cmp	rax,	qword [variable_document_count_of_chars]
	je	.end

	mov	ax,	0x0109
	mov	bl,	VARIABLE_FALSE	; w górę
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	rcx,	VARIABLE_MOKO_INTERFACE_HEIGHT - VARIABLE_DECREMENT
	mov	rdx,	VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT + VARIABLE_INCREMENT
	int	0x40

	add	qword [variable_document_line_start],	0x01

	jmp	.scrolled

.lines_available:
	add	dword [variable_cursor_position + 0x04],	VARIABLE_INCREMENT
	
.scrolled:
	mov	rsi,	qword [variable_cursor_indicator]
	sub	rsi,	qword [variable_cursor_position_on_line]
	add	rsi,	qword [variable_line_count_of_chars]
	add	rsi,	VARIABLE_INCREMENT
	call	count_chars_in_line

	mov	qword [variable_cursor_indicator],	rsi
	mov	qword [variable_line_count_of_chars],	rcx

	cmp	qword [variable_cursor_position_on_line],	rcx
	jb	.cursor_good

	mov	eax,	dword [variable_screen_size]
	sub	eax,	VARIABLE_DECREMENT

	mov	qword [variable_line_print_start],	VARIABLE_EMPTY
	mov	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY

	cmp	rcx,	rax
	jbe	.cursor_was_good

.cursor_fix:
	cmp	rcx,	rax
	jbe	.cursor_good

	sub	rcx,	rax
	add	qword [variable_line_print_start],	rax
	add	qword [variable_cursor_indicator],	rax
	add	qword [variable_cursor_position_on_line],	rax
	jmp	.cursor_fix

.cursor_was_good:
	add	qword [variable_cursor_position_on_line],	rcx
	mov	dword [variable_cursor_position],	ecx
	jmp	.cursor_indicator

.cursor_good:
	mov	rcx,	qword [variable_cursor_position_on_line]

.cursor_indicator:
	add	qword [variable_cursor_indicator],	rcx
	call	update_line_on_screen

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

.end:
	jmp	start.noKey
