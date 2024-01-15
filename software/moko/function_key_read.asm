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

key_function_read:
	; obsłużono klawisz funkcyjny, wyłącz semafor
	mov	byte [variable_semaphore_key_ctrl],	VARIABLE_FALSE

	; ustaw kursor w wierszu informacyjnym
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	ebx,	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	sub	ebx,	VARIABLE_MOKO_INTERFACE_INTERACTIVE
	shl	rbx,	32	; przesuń do pozycji wiersza
	push	rbx	; zapamiętaj
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; zmień kolor linii zapytań
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_BLACK
	mov	ecx,	dword [variable_screen_size]	; szerokość ekranu w znakach
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_LIGHT_GRAY
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; ustaw kursor w wierszu informacyjnym
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [rsp]
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; wyświetl pytanie
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_BLACK
	mov	rcx,	VARIABLE_FULL	; wyświetl pełny ciąg znaków, zakończony terminatorem
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_LIGHT_GRAY
	mov	rsi,	text_open_file
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; rozmiar polecenia do pobrania
	mov	ecx,	dword [variable_screen_size]
	sub	ecx,	dword [text_open_file_chars]	; ilość znaków już wykorzystana w linii
	dec	ecx

	; gdzie przechować wprowadzony ciąg znaków
	mov	rdi,	file_name_buffor
	; rozmiar bufora (jeśli zawiera jakiekolwiek dane)
	mov	r8,	qword [file_name_chars_count]
	; pobierz od użytkownika tekst
	call	library_input
	jc	.file_name

.end:
	; ustaw kursor
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	pop	rbx
	int	STATIC_KERNEL_SERVICE

	; wyczyść linię zapytań
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	ecx,	dword [variable_screen_size]	; szerokość ekranu w znakach
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; ustaw kursor
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [variable_cursor_position]
	int	STATIC_KERNEL_SERVICE

	; zakończ obługę funkcji
	jmp	start.noKey

.file_name:
	; szukaj słowa
	call	library_find_first_word
	jc	.end

	; przesuń słowo na początek bufora nazwy pliku
	mov	rsi,	file_name_buffor

	; ustaw na swoje miejsca
	xchg	rdi,	rsi
	; zapamiętaj rozmiar słowa na przyszłość
	mov	qword [file_name_chars_count],	rcx
	; przesuń
	rep	movsb

	; załaduj plik do przestrzeni dokumentu
	mov	rax,	VARIABLE_KERNEL_SERVICE_VFS_FILE_READ
	mov	rcx,	qword [file_name_chars_count]
	mov	rsi,	file_name_buffor
	mov	rdi,	qword [variable_document_address_start]
	int	STATIC_KERNEL_SERVICE

	cmp	ebx,	VARIABLE_EMPTY
	ja	.end	; lub wyświetl informację, pliku nie znaleziono i pozwól na poprawę nazwy (do zrobienia)

	; zapisz identyfikator załadowanego pliku
	mov	qword [file_identificator],	rdx

	; ustal koniec załadowanego dokumentu
	mov	rdi,	rcx
	add	rdi,	qword [variable_document_address_start]
	call	library_align_address_up_to_page

	; czy plik był pusty?
	cmp	rdi,	qword [variable_document_address_start]
	je	.empty_file

	; zapisz
	mov	qword [variable_document_address_end],	rdi

.empty_file:
	; wyczyść pozostałą część przestrzeni pamięci dokumentu (strony)
	; dmucham na zimne

	; ustal początek przestrzeni czyszczonej
	mov	rdi,	qword [variable_document_address_start]
	add	rdi,	rcx

	; ustal rozmiar przestrzeni czyszczonej
	mov	rcx,	qword [variable_document_address_end]
	sub	rcx,	rdi

	; zapamiętaj rozmiar pliku w znakach
	mov	qword [variable_document_count_of_chars],	rcx

	xor	al,	al

.loop:
	; wyczyść
	stosb
	loop	.loop

	; ustaw kursor w nagłówku
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	xor	rbx,	rbx
	int	STATIC_KERNEL_SERVICE

	; wyczyść nagłówek
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	rbx,	VARIABLE_COLOR_BLACK
	mov	ecx,	dword [variable_screen_size]	; szerokość ekranu w znakach
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_LIGHT_GRAY
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; ustaw kursor w nagłówku
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	ebx,	1
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; wyświetl nawę pliku w nagłówku
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_BLACK
	mov	rcx,	qword [file_name_chars_count]	; przywróć ilość znaków przypadających na nazwe pliku
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_LIGHT_GRAY
	mov	rsi,	file_name_buffor	; przywróć wskaźnik do nazwy pliku
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; inicjalizacja załadowanego dokumentu -------------------------

	; wyświetl zawartość dokumentu od pierwszej linii
	mov	qword [variable_document_line_start],	VARIABLE_EMPTY
	; ustaw kursor na poczatku dokumentu
	mov	rax,	VARIABLE_MOKO_CURSOR_POSITION_INIT
	mov	qword [variable_cursor_position],	rax
	mov	rax,	qword [variable_document_address_start]
	mov	qword [variable_cursor_indicator],	rax
	mov	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY

	; oblicz rozmiar pierwszej linii
	mov	rsi,	qword [variable_document_address_start]
	call	count_chars_in_line
	mov	qword [variable_line_count_of_chars],	rcx
	; wyświetl linię od początku
	mov	qword [variable_line_print_start],	VARIABLE_EMPTY

	mov	qword [variable_document_count_of_lines],	VARIABLE_EMPTY
	mov	rcx,	qword [variable_document_count_of_chars]

	push	rsi

	; dokument pusty?
	cmp	rcx,	VARIABLE_EMPTY
	je	.only_one_line

.count_lines:
	cmp	byte [rsi],	VARIABLE_ASCII_CODE_NEWLINE
	jne	.check

	add	qword [variable_document_count_of_lines],	VARIABLE_INCREMENT

.check:
	add	rsi,	VARIABLE_INCREMENT
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.count_lines

.only_one_line:
	; wyczyść przestrzeń dokumentu
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CLEAN	; procedura czyszcząca ekran
	mov	rbx,	VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT	; za nagłówkiem
	mov	ecx,	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	sub	rcx,	VARIABLE_MOKO_INTERFACE_HEIGHT	; tylko przestrzeń dokumentu
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; ustaw kursor na początku przestrzeni dokumentu
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	VARIABLE_MOKO_CURSOR_POSITION_INIT
	int	STATIC_KERNEL_SERVICE	; wykonaj

	pop	rsi

	mov	ecx,	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	sub	rcx,	VARIABLE_MOKO_INTERFACE_HEIGHT

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

.print:
	cmp	byte [rsi],	VARIABLE_ASCII_CODE_TERMINATOR
	je	.end

	cmp	byte [rsi],	VARIABLE_ASCII_CODE_NEWLINE
	je	.new_line

	push	rcx

	call	count_chars_in_line

	push	rcx

	cmp	ecx,	dword [variable_screen_size]
	jb	.line_size_ok

	mov	ecx,	dword [variable_screen_size]
	sub	ecx,	VARIABLE_DECREMENT

.line_size_ok:
	; wyświetl linię
	int	STATIC_KERNEL_SERVICE	; wykonaj

	pop	rcx

	add	rsi,	rcx

	pop	rcx

	; kontynuuj
	jmp	.print

.new_line:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; wyświetl spacje do końca linii
	mov	rcx,	VARIABLE_FULL
	mov	rsi,	text_new_line
	int	STATIC_KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

	add	rsi,	VARIABLE_INCREMENT

	; kontynuuj
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.print

	jmp	.end

file_identificator			dq	VARIABLE_EMPTY
file_name_chars_count			dq	VARIABLE_EMPTY
file_name_buffor	times	256	db	VARIABLE_EMPTY
					db	VARIABLE_ASCII_CODE_TERMINATOR

text_open_file				db	'Open file: ', VARIABLE_ASCII_CODE_TERMINATOR
text_open_file_chars			dd	11
