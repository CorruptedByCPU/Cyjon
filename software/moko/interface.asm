;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
moko_interface:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; wyczyść ekran i ustaw na pozycję przestrzeni menu
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_cursor_at_menu_and_clear_screen_end - moko_string_cursor_at_menu_and_clear_screen
	mov	rsi,	moko_string_cursor_at_menu_and_clear_screen
	int	KERNEL_SERVICE

	; wyświetl
	mov	ecx,	moko_string_menu_end - moko_string_menu
	mov	rsi,	moko_string_menu
	int	KERNEL_SERVICE

	; ustaw kursor na początek dokumentu
	mov	ecx,	moko_string_document_cursor_end - moko_string_document_cursor
	mov	rsi,	moko_string_document_cursor
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
