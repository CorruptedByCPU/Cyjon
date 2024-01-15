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

key_arrow_left:
	cmp	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY
	ja	.position_ok

	cmp	qword [variable_line_print_start],	VARIABLE_EMPTY
	je	.change_line

	dec	qword [variable_line_print_start]
	dec	qword [variable_cursor_indicator]
	dec	qword [variable_cursor_position_on_line]
	call	update_line_on_screen

	jmp	start.noKey

.change_line:
	cmp	dword [variable_cursor_position + 0x04], VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT
	je	.scroll_down

	sub	dword [variable_cursor_position + 0x04],	VARIABLE_DECREMENT

.line_ok:
	; pomiń znak nowej linii
	sub	qword [variable_cursor_indicator],	VARIABLE_DECREMENT
	mov	rsi,	qword [variable_cursor_indicator]
	call	count_chars_in_previous_line

	mov	qword [variable_line_count_of_chars],	rcx
	mov	qword [variable_cursor_position_on_line],	rcx

	cmp	ecx,	dword [variable_screen_size]
	jb	.line_size_ok

	mov	eax,	dword [variable_screen_size]
	sub	eax,	0x01
	sub	rcx,	rax
	mov	qword [variable_line_print_start],	rcx
	mov	dword [variable_cursor_position],	eax
	call	update_line_on_screen

	jmp	start.noKey

.line_size_ok:
	mov	dword [variable_cursor_position],	ecx
	call	update_line_on_screen

	jmp	start.noKey

.scroll_down:
	; sprawdź czy istnieją poprzednie linie
	cmp	qword [variable_document_line_start],	VARIABLE_EMPTY
	je	.end	; brak

	; sprawdź czy wyświetlić aktualną linię od początku
	cmp	qword [variable_line_print_start],	VARIABLE_EMPTY
	je	.line_good

	mov	qword [variable_line_print_start],	VARIABLE_EMPTY
	call	update_line_on_screen

.line_good:
	mov	ax,	0x0109
	mov	bl,	VARIABLE_TRUE	; w dół
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	rcx,	VARIABLE_MOKO_INTERFACE_HEIGHT
	mov	rdx,	VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT
	int	0x40

	sub	qword [variable_document_line_start],	VARIABLE_DECREMENT

	jmp	.line_ok

.position_ok:
	cmp	dword [variable_cursor_position],	VARIABLE_EMPTY
	je	.no_cursor

	sub	dword [variable_cursor_position],	0x01
	sub	qword [variable_cursor_indicator],	0x01
	sub	qword [variable_cursor_position_on_line],	0x01

	jmp	.update_cursor

.no_cursor:
	sub	qword [variable_line_print_start],	0x01

.new_line_start:
	sub	qword [variable_cursor_indicator],	0x01
	sub	qword [variable_cursor_position_on_line],	0x01

	call	update_line_on_screen

.update_cursor:
	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

.end:
	jmp	start.noKey
