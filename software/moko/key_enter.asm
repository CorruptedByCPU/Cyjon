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

key_enter:
	; załaduj znak nowej linii
	mov	ax,	VARIABLE_ASCII_CODE_NEWLINE
	call	save_into_document

	add	qword [variable_document_count_of_chars],	VARIABLE_INCREMENT
	add	qword [variable_document_count_of_lines],	VARIABLE_INCREMENT

	; aktualizuj nowy rozmiar aktualnej linii
	mov	rax,	qword [variable_cursor_position_on_line]
	mov	qword [variable_line_count_of_chars],	rax

	; wyświetl aktualną linię od początku
	sub	qword [variable_cursor_indicator],	rax
	mov	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY
	mov	qword [variable_line_print_start],	VARIABLE_EMPTY

	call	update_line_on_screen

	mov	dword [variable_cursor_position],	VARIABLE_EMPTY

	; utwórz miejsce na ekranie dokumentu dla nowej linii

	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	ecx,	VARIABLE_MOKO_INTERFACE_MENU_HEIGHT
	sub	ecx,	VARIABLE_DECREMENT
	mov	ebx,	dword [variable_cursor_position + 0x04]
	cmp	ebx,	ecx
	je	.scroll_up

	; scroll down
	mov	ax,	0x0109
	mov	bl,	VARIABLE_TRUE	 ; w dół
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	ecx,	dword [variable_cursor_position + 0x04]
	; druga dekrementacja dotyczy pozycji kursora liczonej od zera, a nie od 1
	sub	ecx,	VARIABLE_MOKO_INTERFACE_MENU_HEIGHT + VARIABLE_DECREMENT + VARIABLE_DECREMENT
	jz	.last_line

	mov	edx,	dword [variable_cursor_position + 0x04]
	add	edx,	VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT
	int	0x40

.last_line:
	add	dword [variable_cursor_position + 0x04],	0x01

	jmp	.show_new_line

.scroll_up:
	mov	ax,	0x0109
	mov	bl,	VARIABLE_FALSE	; w górę
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	rcx,	VARIABLE_MOKO_INTERFACE_HEIGHT - VARIABLE_DECREMENT
	mov	rdx,	VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT + VARIABLE_INCREMENT
	int	0x40

	add	qword [variable_document_line_start],	0x01

.show_new_line:
	; pomiń znak nowej linii
	xchg	rdi,	rsi
	call	count_chars_in_line

	mov	qword [variable_cursor_indicator],	rsi
	mov	qword [variable_line_count_of_chars],	rcx
	mov	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY
	call	update_line_on_screen

	jmp	start.noKey
