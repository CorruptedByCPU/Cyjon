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

check_cursor:
	push	rax

	; sprawdź pozycję kolumny
	mov	eax,	dword [variable_screen_size]
	cmp	eax,	dword [variable_cursor_position]
	jne	.column_ok

	inc	qword [variable_line_print_start]
	dec	dword [variable_cursor_position]

.column_ok:
	; sprawdź pozycję wiersza
	mov	eax,	dword [variable_screen_size + 0x04]
	sub	eax,	VARIABLE_MOKO_INTERFACE_MENU_HEIGHT
	cmp	eax,	dword [variable_cursor_position + 0x04]
	jne	.row_ok

	inc	qword [variable_document_line_start]
	dec	dword [variable_cursor_position + 0x04]

.row_ok:
	pop	rax

	; powrót z procedury
	ret
