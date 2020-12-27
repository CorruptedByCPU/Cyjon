;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	ax - kod klawisza
moko_shortcut:
	; przytrzymano klawisz CTRL?
	cmp	byte [moko_key_ctrl_semaphore],	STATIC_FALSE
	je	.no_key	; nie

	; naciśnięto klawisz "x"?
	cmp	ax,	"x"
	je	moko.end	; tak

	; naciśnięto klawisz "r"?
	cmp	ax,	"r"
	je	.read_file	; tak

.no_key:
	; nie rozpoznano skrótu klawiszowego
	stc

.end:
	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
.read_file:
	; zwolnij klawisz CTRL
	mov	byte [moko_key_ctrl_semaphore],	STATIC_FALSE

	; zachowaj pozycję kursora
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_cursor_save_end - moko_string_cursor_save
	mov	rsi,	moko_string_cursor_save
	int	KERNEL_SERVICE

	; ustaw kursor na pozycję komunikacji z użyszkodnikiem
	mov	ecx,	moko_string_document_cursor_end - moko_string_document_cursor
	mov	rsi,	moko_string_document_cursor
	mov	word [moko_string_document_cursor.x],	STATIC_EMPTY
	mov	word [moko_string_document_cursor.y],	r9w
	inc	word [moko_string_document_cursor.y]
	int	KERNEL_SERVICE

	; wyświetl zapytanie o nazwę pliku
	mov	ecx,	moko_string_menu_read_end - moko_string_menu_read
	mov	rsi,	moko_string_menu_read
	int	KERNEL_SERVICE

	; pobierz nazwę pliku(ścieżkę)
	mov	rbx,	qword [moko_cache_size_byte]	; rozmiar bufora
	xor	ecx,	ecx	; bufor pusty
	mov	rdx,	moko_ipc	; obsługa wyjątków
	mov	rsi,	qword [moko_cache_address]
	mov	rdi,	moko_ipc_data
	call	library_input

	; zachowaj stan flagi CF
	pushf

	; wyczyść zapytanie
	call	.read_file_clean

	; przywróć stan flagi CF
	popf

	; nie pobrano nazwy pliku/ścieżki?
	jc	.read_file_error	; tak

	; usuń z ciągu "białe znaki"
	call	library_string_trim
	jc	.read_file_error	; ciąg jest pusty

	; przetwórz dokument/plik
	call	moko_document_format
	jnc	moko_shortcut.end

.read_file_error:
	; przywróć pozycję kursora
	mov	ecx,	moko_string_cursor_restore_end - moko_string_cursor_restore
	mov	rsi,	moko_string_cursor_restore
	int	KERNEL_SERVICE

	; koniec obsługi skrótu klawiszowego
	jmp	moko_shortcut.end

.read_file_clean:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; usuń zapytanie o nazwę pliku
	mov	ecx,	moko_string_line_clean_end - moko_string_line_clean
	mov	rsi,	moko_string_line_clean
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

	; powrót z podprocedury
	ret
