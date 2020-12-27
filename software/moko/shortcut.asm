;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wyjście:
;	Flaga CF - jeśli błąd
;	rcx - ilość znaków w nazwie pliku
;	rsi - wskaźnik do ciągu przechowującego nazwę/ścieżkę pliku
moko_shortcut_file:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rdi
	push	rsi
	push	rcx

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

	; zachowaj oryginalne rejestry oraz stan flagi CF
	pushf
	push	rcx
	push	rsi

	; usuń zapytanie o nazwę pliku
	mov	ecx,	moko_string_line_clean_end - moko_string_line_clean
	mov	rsi,	moko_string_line_clean
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry oraz stan flagi CF
	pop	rsi
	pop	rcx
	popf

	; nie pobrano nazwy pliku/ścieżki?
	jc	.end	; tak

	; usuń z ciągu "białe znaki"
	call	library_string_trim
	jc	.end	; pusty ciąg

	; zwróć informacje o ciągu
	mov	qword [rsp],	rcx
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rsi

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rsi
	pop	rdi
	pop	rdx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

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

	; naciśnięto klawisz "o"?
	cmp	ax,	"o"
	je	.save_file	; tak

	; nie rozpoznano skrótu klawiszowego
	jmp	.no_key

.restore_cursor:
	; przywróć pozycję kursora
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_cursor_restore_end - moko_string_cursor_restore
	mov	rsi,	moko_string_cursor_restore
	int	KERNEL_SERVICE

.no_key:
	; nie rozpoznano skrótu klawiszowego
	stc

.end:
	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
.save_file:
	; pobierrz nazwę pliku od użyszkodnika
	call	moko_shortcut_file
	jc	moko_shortcut.restore_cursor	; nie podano nazwy pliku

	; debug
	jmp	moko_shortcut.end

	; zapisz zawartość dokumentu do pliku o podanej nazwie
	mov	ax,	KERNEL_SERVICE_VFS_write
	mov	rdx,	qword [moko_document_size]
	mov	rdi,	qword [moko_document_start_address]
	int	KERNEL_SERVICE

	; todo

	; koniec obsługi skrótu klawiszowego
	jmp	moko_shortcut.end

;-------------------------------------------------------------------------------
.read_file:
	; pobierz nazwę pliku od użyszkodnika
	call	moko_shortcut_file
	jc	moko_shortcut.restore_cursor	; nie podano nazwy pliku

	; przetwórz dokument/plik
	call	moko_document_format
	jnc	moko_shortcut.end

	; todo

	; koniec obsługi skrótu klawiszowego
	jmp	moko_shortcut.end
