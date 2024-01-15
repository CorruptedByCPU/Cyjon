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

update_line_on_screen:
	push	rax
	push	rbx
	push	rcx
	push	rdx

	; kursor na początek linii
	mov	ax,	0x0105
	mov	ebx,	dword [variable_cursor_position + 0x04]
	shl	rbx,	32
	int	0x40

	mov	rsi,	qword [variable_cursor_indicator]
	sub	rsi,	qword [variable_cursor_position_on_line]
	add	rsi,	qword [variable_line_print_start]

	mov	rcx,	qword [variable_line_count_of_chars]
	sub	rcx,	qword [variable_line_print_start]
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
	je	.end

	xchg	rax,	rcx
	sub	rcx,	rax
	mov	ax,	0x0102
	mov	r8,	" "
	int	0x40

.end:
	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
