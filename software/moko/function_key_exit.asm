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

key_function_exit:
	cmp	byte [variable_semaphore_status],	VARIABLE_FALSE
	je	.shutdown

	; cdn

.shutdown:
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	ebx,	dword [variable_screen_size + 0x04]
	dec	ebx
	shl	rbx,	32
	int	0x40

	; wyświetl 
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	-1	; wyświetl pełny ciąg znaków, zakończony terminatorem
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_new_line
	int	0x40

	; VARIABLE_KERNEL_SERVICE_PROCESS_KILL
	xor	rax,	rax
	int	0x40
