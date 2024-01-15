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

key_arrow_right:
	mov	rsi,	qword [variable_cursor_indicator]
	cmp	byte [rsi],	VARIABLE_EMPTY
	je	start.noKey

	mov	rax,	qword [variable_cursor_position_on_line]
	cmp	rax,	qword [variable_line_count_of_chars]
	je	.change_line

	mov	eax,	dword [variable_screen_size]
	sub	eax,	VARIABLE_DECREMENT
	cmp	dword [variable_cursor_position],	eax
	jb	.cursor_ok

	; kursor pozostaje w miejscu
	add	qword [variable_cursor_indicator],	VARIABLE_INCREMENT
	add	qword [variable_cursor_position_on_line],	VARIABLE_INCREMENT
	add	qword [variable_line_print_start],	VARIABLE_INCREMENT

	call	update_line_on_screen

	jmp	start.noKey

.cursor_ok:
	add	qword [variable_cursor_indicator],	VARIABLE_INCREMENT
	add	dword [variable_cursor_position],	VARIABLE_INCREMENT
	add	qword [variable_cursor_position_on_line],	VARIABLE_INCREMENT

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	jmp	start.noKey

.change_line:
	mov	eax,	dword [variable_screen_size + 0x04]
	sub	eax,	VARIABLE_DECREMENT + VARIABLE_MOKO_INTERFACE_MENU_HEIGHT
	mov	ebx,	dword [variable_cursor_position + 0x04]
	cmp	ebx,	eax
	je	.scroll_up

	; sprawdź czy wyświetlić aktualną linię od początku
	cmp	qword [variable_line_print_start],	VARIABLE_EMPTY
	je	.line_correct

	mov	qword [variable_line_print_start],	VARIABLE_EMPTY
	call	update_line_on_screen

.line_correct:
	add	dword [variable_cursor_position + 0x04],	VARIABLE_INCREMENT

	; przesuń wskaźnik do nastepnej linii
	add	qword [variable_cursor_indicator],	VARIABLE_INCREMENT
	mov	rsi,	qword [variable_cursor_indicator]
	call	count_chars_in_line

	mov	qword [variable_cursor_indicator],	rsi
	mov	qword [variable_line_count_of_chars],	rcx
	mov	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY
	mov	dword [variable_cursor_position],	VARIABLE_EMPTY

	jmp	.end

.scroll_up:
	; sprawdź czy wyświetlić aktualną linię od początku
	cmp	qword [variable_line_print_start],	VARIABLE_EMPTY
	je	.line_good

	mov	qword [variable_line_print_start],	VARIABLE_EMPTY
	call	update_line_on_screen

.line_good:
	mov	ax,	0x0109
	mov	bl,	VARIABLE_FALSE
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	rcx,	VARIABLE_MOKO_INTERFACE_HEIGHT
	mov	rdx,	VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT + VARIABLE_INCREMENT
	int	0x40

	; przesuń wskaźnik do nastepnej linii
	add	qword [variable_cursor_indicator],	VARIABLE_INCREMENT
	mov	rsi,	qword [variable_cursor_indicator]
	call	count_chars_in_line

	add	qword [variable_document_line_start],	VARIABLE_INCREMENT
	mov	qword [variable_cursor_indicator],	rsi
	mov	qword [variable_line_count_of_chars],	rcx
	mov	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY
	mov	dword [variable_cursor_position],	VARIABLE_EMPTY
	call	update_line_on_screen

.end:
	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	jmp	start.noKey
