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

key_end:
	mov	rax,	qword [variable_cursor_position_on_line]
	mov	rcx,	qword [variable_line_count_of_chars]
	mov	qword [variable_cursor_position_on_line],	rcx
	sub	qword [variable_cursor_indicator],	rax
	add	qword [variable_cursor_indicator],	rcx

	mov	dword [variable_cursor_position],	ecx

	cmp	ecx,	dword [variable_screen_size]
	jb	.ok

	sub	ecx,	dword [variable_screen_size]
	sub	rcx,	VARIABLE_DECREMENT
	mov	qword [variable_line_print_start],	rcx
	mov	ecx,	dword [variable_screen_size]
	sub	rcx,	VARIABLE_DECREMENT
	mov	dword [variable_cursor_position],	ecx

	call	update_line_on_screen

.ok:
	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	jmp	start.noKey
