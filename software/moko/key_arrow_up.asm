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

key_arrow_up:
	push	qword [variable_line_print_start]

	mov	qword [variable_line_print_start],	VARIABLE_EMPTY
	call	update_line_on_screen

	pop	qword [variable_line_print_start]

	cmp	dword [variable_cursor_position + 0x04],	VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT
	ja	.lines_available

	cmp qword [variable_document_line_start],	VARIABLE_EMPTY
	je	.end	; brak możliwości

	; scroll down
	mov	ax,	0x0109
	mov	bl,	VARIABLE_TRUE	 ; w dół
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	ecx,	dword [variable_cursor_position + 0x04]
	; druga dekrementacja dotyczy pozycji kursora liczonej od zera, a nie od 1
	sub	ecx,	VARIABLE_MOKO_INTERFACE_MENU_HEIGHT + VARIABLE_DECREMENT
	mov	edx,	dword [variable_cursor_position + 0x04]
	add	edx,	VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT - VARIABLE_DECREMENT * 0x02
	int	0x40

	sub	qword [variable_document_line_start],	VARIABLE_DECREMENT

	jmp	.scrolled

.lines_available:
	sub	dword [variable_cursor_position + 0x04],	VARIABLE_DECREMENT
	
.scrolled:
	mov	rsi,	qword [variable_cursor_indicator]
	sub	rsi,	qword [variable_cursor_position_on_line]
	sub	rsi,	VARIABLE_DECREMENT
	call	count_chars_in_previous_line

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
