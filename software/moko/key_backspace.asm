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

key_backspace:
	mov	rsi,	qword [variable_cursor_indicator]
	cmp	rsi,	qword [variable_document_address_start]
	je	start.noKey

	call	save_into_document

	sub	qword [variable_cursor_indicator],	VARIABLE_DECREMENT
	sub	qword [variable_document_count_of_chars],	VARIABLE_DECREMENT

	cmp	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY
	je	.change_line

	sub	qword [variable_cursor_position_on_line],	VARIABLE_DECREMENT
	sub	qword [variable_line_count_of_chars],	VARIABLE_DECREMENT

	cmp	dword [variable_cursor_position],	VARIABLE_EMPTY
	je	.change_line_start

	sub	dword [variable_cursor_position],	VARIABLE_DECREMENT
	jmp	.cursor_moved

.change_line_start:
	sub	qword [variable_line_print_start],	VARIABLE_DECREMENT

.cursor_moved:
	call	update_line_on_screen

	jmp	start.noKey

.change_line:
	mov	rsi,	qword [variable_cursor_indicator]
	call	count_chars_in_previous_line

	cmp	dword [variable_cursor_position + 0x04],	VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT
	je	.no_decrement

	sub	dword [variable_cursor_position + 0x04],	VARIABLE_DECREMENT
	mov	byte [variable_semaphore_backspace],	VARIABLE_TRUE

	jmp	.continue

.no_decrement:
	cmp	qword [variable_document_line_start],	VARIABLE_EMPTY
	je	.continue

	sub	qword [variable_document_line_start],	VARIABLE_DECREMENT

.continue:
	sub	qword [variable_document_count_of_lines],		VARIABLE_DECREMENT

	add	qword [variable_line_count_of_chars],	rcx
	mov	qword [variable_cursor_position_on_line],	rcx

	mov	eax,	dword [variable_screen_size]
	sub	eax,	VARIABLE_DECREMENT

.cursor_fix:
	cmp	rcx,	rax
	jbe	.cursor_fixed

	sub	rcx,	rax
	add	qword [variable_line_print_start],	rax
	jmp	.cursor_fix

.cursor_fixed:
	mov	dword [variable_cursor_position],	ecx
	call	update_line_on_screen

	cmp	byte [variable_semaphore_backspace],	VARIABLE_FALSE
	je	.nothing_to_do

	mov	byte [variable_semaphore_backspace],	VARIABLE_FALSE

	; przesuń dolną część ekranu do góry
	mov	ax,	0x0109
	mov	rbx,	VARIABLE_FALSE	; w górę
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	ecx,	dword [variable_cursor_position + 0x04]
	sub	rcx,	VARIABLE_MOKO_INTERFACE_HEIGHT - VARIABLE_DECREMENT
	mov	edx,	dword [variable_cursor_position + 0x04]
	add 	rdx,	VARIABLE_INCREMENT + VARIABLE_INCREMENT
	int	0x40

	; sprawdź czy zaaktualizować ostatnią linię na ekranie
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	ecx,	VARIABLE_MOKO_INTERFACE_HEIGHT + VARIABLE_DECREMENT
	add	rcx,	qword [variable_document_line_start]
	mov	rax,	qword [variable_document_count_of_lines]
	cmp	rcx,	rax
	ja	.nothing_to_do

	call	find_line_indicator
	call	count_chars_in_line

	; kursor na początek linii
	mov	ax,	0x0105
	mov	ebx,	dword [variable_screen_size + 0x04]
	sub	rbx,	VARIABLE_MOKO_INTERFACE_MENU_HEIGHT + VARIABLE_DECREMENT
	shl	rbx,	32
	int	0x40

	cmp	ecx,	dword [variable_screen_size]
	jb	.size_of_line_ok

	mov	ecx,	dword [variable_screen_size]
	sub	ecx,	1

.size_of_line_ok:
	mov	ax,	0x0101
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	0x40

	; spawdź czy wyczyścić pozostałą część linii
	mov	eax,	dword [variable_screen_size]
	sub	rax,	1
	cmp	rcx,	rax	; ostatnia kolumna pozostaje pusta
	je	.nothing_to_do

	xchg	rax,	rcx
	sub	rcx,	rax
	mov	ax,	0x0102
	mov	r8,	" "
	int	0x40

.nothing_to_do:
	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

.end:
	jmp	start.noKey
