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

save_into_document:
	; sprawdź dostępność miejsca w dokumencie
	mov	rdi,	qword [variable_document_address_start]
	add	rdi,	qword [variable_document_count_of_chars]

	cmp	rdi,	qword [variable_document_address_end]
	jb	.space_available

	push	rax

	; poproś o dodatkową przestrzeń pod dokument
	mov	ax,	0x0003
	mov	rcx,	1
	int	0x40

	add	qword [variable_document_address_end],	VARIABLE_MEMORY_PAGE_SIZE

	pop	rax

.space_available:
	cmp	ax,	VARIABLE_ASCII_CODE_BACKSPACE
	je	.backspace

	; wstaw znak na koniec dokumentu?
	mov	rdi,	qword [variable_document_address_start]
	add	rdi,	qword [variable_document_count_of_chars]
	cmp	rdi,	qword [variable_cursor_indicator]
	je	.at_end_of_document

	; wstaw znak gdzieś w dokumencie

	; utwórz miejsce dla znaku w dokumencie
	mov	rcx,	rdi
	mov	rsi,	rdi
	dec	rsi
	sub	rcx,	qword [variable_cursor_indicator]

	push	rax

.loop:
	mov	al,	byte [rsi]
	mov	byte [rdi],	al
	sub	rdi,	1
	sub	rsi,	1
	sub	rcx,	1
	jnz	.loop

	pop	rax

	jmp	.save_char

.at_end_of_document:
	; zapisz znak do dokumentu
	mov	rdi,	qword [variable_cursor_indicator]

.save_char:
	stosb

	ret

.backspace:
	mov	rsi,	qword [variable_cursor_indicator]
	mov	rdi,	rsi
	sub	rdi,	VARIABLE_DECREMENT
	mov	rax,	rsi
	sub	rax,	qword [variable_document_address_start]
	mov	rcx,	qword [variable_document_count_of_chars]
	sub	rcx,	rax
	add	rcx,	VARIABLE_INCREMENT

.delete_char:
	mov	al,	byte [rsi]
	mov	byte [rdi],	al
	add	rdi,	VARIABLE_INCREMENT
	add	rsi,	VARIABLE_INCREMENT
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.delete_char

	ret
