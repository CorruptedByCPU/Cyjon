;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
moko_status:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; zachowaj pozycję kursora
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_cursor_save_end - moko_string_cursor_save
	mov	rsi,	moko_string_cursor_save
	int	KERNEL_SERVICE

	; ustaw kursor na pozycję komunikacji z użyszkodnikiem
	mov	ecx,	moko_string_document_cursor_end - moko_string_document_cursor
	mov	rsi,	moko_string_document_cursor
	mov	word [moko_string_document_cursor.x],	r8w
	sub	word [moko_string_document_cursor.x],	moko_string_document_cursor_end - moko_string_document_cursor
	mov	word [moko_string_document_cursor.y],	r9w
	inc	word [moko_string_document_cursor.y]
	int	KERNEL_SERVICE

	; dokument został zmodyfikowany od ostatniego zapisu/odczytu?
	cmp	byte [moko_modified_semaphore],	STATIC_FALSE
	je	.no_modified	; nie

	; wyświetl informacje o zmodyfikowanym dokumencie
	mov	ecx,	moko_string_modified_end - moko_string_modified
	mov	rsi,	moko_string_modified
	int	KERNEL_SERVICE

	; wyświetlono status dokumentu
	mov	byte [moko_modified_semaphore],	STATIC_FALSE

.no_modified:
	; przywróć pozycję kursora
	mov	ecx,	moko_string_cursor_restore_end - moko_string_cursor_restore
	mov	rsi,	moko_string_cursor_restore
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
