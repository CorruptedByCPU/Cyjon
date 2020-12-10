;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rcx - ilość znaków ciągu
;	rsi - wskaźnik do ciągu
;	r8 - wskaźnik do właściwości terminala
console_sequence:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdi

	; rozmiar ciągu może zawierać sekwencje?
	cmp	rcx,	STATIC_SEQUENCE_length_min
	jb	.error	; nie

	; pierwszy znak należy do sekwencji?
	cmp	byte [rsi],	STATIC_SCANCODE_CARET
	jne	.error	; nie

	; polecenie do wykonania?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte],	"["
	jne	.error	; nie

	; zmiana koloru?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x02],	"c"
	je	.color	; tak

	; modyfikacja przestrzeni konsoli?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x02],	"t"
	je	.terminal	; tak

	; zmiana nagłówka okna konsoli?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x02],	"h"
	je	.header	; tak

.error:
	; brak obsługi sekwencji
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
.header:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi
	push	rsi
	push	rcx

	; przesuń wskaźnik na nazwę nowego nagłówka okna oraz ogranicz rozmiar pozostałego ciągu
	sub	rcx,	0x03
	add	rsi,	0x03

	; rozpoznaj nazwę nagłówka (ilośc znaków wchodzących w jego skład)
	mov	al,	"]"
	call	library_string_cut
	jc	.header_end	; nie znaleziono końca sekwencji

	; utwórz nowy nagłówek
	mov	rdi,	console_window
	call	library_bosu_header_set

	; rozpoczęcie i zakończenie sekwencji
	add	rcx,	0x04

	; przetworzono sekwencję
	sub	qword [rsp],	rcx
	; zwróć informacje o pozostałym ciągu do przetworzenia
	add	qword [rsp + STATIC_QWORD_SIZE_byte],	rcx

.header_end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rsi
	pop	rdi
	pop	rax

	; powrót z podprocedury
	jmp	console_sequence.end

;-------------------------------------------------------------------------------
.color:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi

	; tablica kolorów
	mov	rdi,	console_table_color

	; pobierz kod koloru
	movzx	eax,	byte [rsi + STATIC_BYTE_SIZE_byte * 0x04]

	; brak koloru znaku?
	cmp	al,	"*"
	je	.color_background_only	; tak

	; ustaw kolor znaku
	call	.color_translate
	mov	eax,	dword [rdi + rax * STATIC_DWORD_SIZE_byte]
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	eax

.color_background_only:
	; pobierz kod koloru
	movzx	eax,	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03]

	; brak koloru tła?
	cmp	al,	"*"
	je	.color_ready	; tak

	; ustaw kolor tła
	call	.color_translate
	mov	eax,	dword [rdi + rax * STATIC_DWORD_SIZE_byte]
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.background_color],	eax

%strlen	THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_COLOR_DEFAULT

.color_ready:
	; przetworzono sekwencję
	sub	rcx,	THIS_SEQUENCE_LENGTH
	add	rsi,	THIS_SEQUENCE_LENGTH

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rax

	; powrót z podprocedury
	jmp	console_sequence.end

.color_translate:
	; wartość decymalna?
	cmp	al,	STATIC_SCANCODE_DIGIT_9
	ja	.color_translate_hex

	; zamień na cyfrę 0-9
	sub	al,	STATIC_SCANCODE_DIGIT_0

	; powrót z podprocedury
	ret

.color_translate_hex:
	; zamień na literę A-F
	sub	al,	(STATIC_SCANCODE_HIGH_CASE - (STATIC_SCANCODE_DIGIT_9 - STATIC_SCANCODE_DIGIT_0)) - 0x01

	; powrót z podprocedury
	ret

;-------------------------------------------------------------------------------
.terminal:
	; wyczyścić przestrzeń znakową?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"0"
	jne	.terminal_no_clear	; nie

	; wyczyść przestrzeń znakową konsoli
	call	library_terminal_clear

%strlen	THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_CLEAR

	; przetworzono sekwencję
	sub	rcx,	THIS_SEQUENCE_LENGTH
	add	rsi,	THIS_SEQUENCE_LENGTH

	; powrót z podprocedury
	jmp	console_sequence.end

.terminal_no_clear:
	;-----------------------------------------------------------------------
	;-----------------------------------------------------------------------
	; ustawić kursor na nową pozycję w przestrzeni znakowej?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"1"
	jne	.terminal_no_cursor_position	; nie

	; przesuń wskaźnik na pozycję X kursora
	sub	rcx,	0x05
	add	rsi,	0x05


	; pobierz rozmiar liczby
	mov	bl,	";"
	call	library_string_word_next
	jc	console_sequence.error	; uszkodzona sekwencja

	; rozmiar wartości większy większy od cyfry?
	cmp	rbx,	0x01
	ja	.terminal_cursor_position_column

	; ustawić na ostatną kolumnę aktualnego wiersza?
	cmp	byte [rsi],	STATIC_SCANCODE_ASTERISK
	jne	.terminal_cursor_position_column	; nie

	; numer ostatniej kolumny
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.width_char]
	dec	eax

	; kontynuuj
	jmp	.terminal_cursor_position_column_set

.terminal_cursor_position_column:
	; zamień ciąg cyfr na wartość
	call	library_string_to_integer

.terminal_cursor_position_column_set:
	; ustaw kursor tekstowy na danej kolumnie
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.x],	eax

	; przesuń wskaźnik na pozycję Y kursora
	inc	rbx	; pomiń separator ";"
	sub	rcx,	rbx
	add	rsi,	rbx

	; pobierz rozmiar liczby
	mov	bl,	"]"
	call	library_string_word_next
	jc	console_sequence.error	; uszkodzona sekwencja


	; rozmiar wartości większy większy od cyfry?
	cmp	rbx,	0x01
	ja	.terminal_cursor_position_row

	; ustawić na ostatną kolumnę aktualnego wiersza?
	cmp	byte [rsi],	STATIC_SCANCODE_ASTERISK
	jne	.terminal_cursor_position_row	; nie

	; numer ostatniej kolumny
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.height_char]
	dec	eax

	; kontynuuj
	jmp	.terminal_cursor_position_row_set

.terminal_cursor_position_row:
	; zamień ciąg cyfr na wartość
	call	library_string_to_integer

.terminal_cursor_position_row_set:
	; ustaw kursor tekstowy na danej kolumnie
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y],	eax

.terminal_safe_row:
	; przesuń wskaźnik za sekwencję
	inc	rbx	; pomiń zamknięcie sekwencji "]"
	sub	rcx,	rbx
	add	rsi,	rbx

	; zaktualizuj pozycję kursora tekstowego w konsoli
	call	library_terminal_cursor_set

	; powrót z podprocedury
	jmp	console_sequence.end

.terminal_no_cursor_position:
	;-----------------------------------------------------------------------
	;-----------------------------------------------------------------------
	; przełączyć widoczność kursora?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"2"
	jne	.terminal_no_cursor_visibility	; nie

	; ukryj?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x05],	"1"
	jne	.terminal_show_cursor	; nie

	; ukryj kursor tekstowy
	call	library_terminal_cursor_disable

	; przetworzono sekwencję
	sub	rcx,	0x07
	add	rsi,	0x07

	; powrót z podprocedury
	jmp	console_sequence.end

.terminal_show_cursor:
	; pokaż kursor tekstowy
	call	library_terminal_cursor_enable

	; przetworzono sekwencję
	sub	rcx,	0x07
	add	rsi,	0x07

	; powrót z podprocedury
	jmp	console_sequence.end

.terminal_no_cursor_visibility:
	;-----------------------------------------------------------------------
	;-----------------------------------------------------------------------
	; wyczyścić linię w miejscu kursora?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"3"
	jne	.terminal_no_line_clear	; nie

	; zachowaj oryginalne rejestr
	push	rcx

	; numer linii do wyczyszczenia
	mov	ecx,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y]
	call	library_terminal_empty_line

	; przywróć oryginalny rejestr
	pop	rcx

	; przetworzono sekwencję
	sub	rcx,	0x05
	add	rsi,	0x05

	; powrót z podprocedury
	jmp	console_sequence.end

.terminal_no_line_clear:
	; nie rozpoznano polecenia
	jmp	console_sequence.error
