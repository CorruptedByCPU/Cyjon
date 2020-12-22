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
;-------------------------------------------------------------------------------
.color:
	%strlen	THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_COLOR_DEFAULT

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
;-------------------------------------------------------------------------------
.terminal:
	; wyczyścić przestrzeń znakową?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"0"
	je	.terminal_clear	; tak

	; ustawić kursor na nową pozycję w przestrzeni znakowej?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"1"
	je	.terminal_cursor_position	; tak

	; przełączyć widoczność kursora?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"2"
	je	.terminal_cursor_visibility	; tak

	; wyczyścić linię w miejscu kursora?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"3"
	je	.terminal_line_clear	; tak

	; przesunąć zawartość terminala w górę?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"4"
	je	.terminal_scroll_up	; tak

	; przesunąć zawartość terminala w dół?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"5"
	je	.terminal_scroll_down	; tak

	; nie rozpoznano sekwencji lub uszkodzona
	jmp	console_sequence.error

;-------------------------------------------------------------------------------
.terminal_scroll_up:
	%strlen	THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_SCROOL_UP

	; zachowaj rozmiar ciągu
	push	rcx

	; pobierz ilość linii do przesunięcia
	movzx	ebx,	word [rsi + 0x05]

	; pobierz numer linii od której rozpocząć przesunięcie
	movzx	rcx,	word [rsi + 0x05 + STATIC_WORD_SIZE_byte]

	; wykonaj
	call	library_terminal_scroll_up

	; przywróć rozmiar ciągu
	pop	rcx

	; przetworzono sekwencję
	sub	rcx,	THIS_SEQUENCE_LENGTH
	add	rsi,	THIS_SEQUENCE_LENGTH

	; powrót z podprocedury
	jmp	console_sequence.end

;-------------------------------------------------------------------------------
.terminal_scroll_down:
	%strlen	THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_SCROOL_DOWN

	; zachowaj rozmiar ciągu
	push	rcx

	; pobierz ilość linii do przesunięcia
	movzx	ebx,	word [rsi + 0x05]

	; pobierz numer linii od której rozpocząć przesunięcie
	movzx	rcx,	word [rsi + 0x05 + STATIC_WORD_SIZE_byte]

	; wykonaj
	call	library_terminal_scroll_down

	; przywróć rozmiar ciągu
	pop	rcx

	; przetworzono sekwencję
	sub	rcx,	THIS_SEQUENCE_LENGTH
	add	rsi,	THIS_SEQUENCE_LENGTH

	; powrót z podprocedury
	jmp	console_sequence.end

;-------------------------------------------------------------------------------
.terminal_line_clear:
	%strlen	THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_CLEAR

	; numer linii do wyczyszczenia
	mov	ebx,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y]
	call	library_terminal_empty_line

	; przetworzono sekwencję
	sub	rcx,	THIS_SEQUENCE_LENGTH
	add	rsi,	THIS_SEQUENCE_LENGTH

	; powrót z podprocedury
	jmp	console_sequence.end

;-------------------------------------------------------------------------------
.terminal_clear:
	%strlen	THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_CLEAR

	; wyczyść przestrzeń znakową konsoli
	call	library_terminal_clear

	; przetworzono sekwencję
	sub	rcx,	THIS_SEQUENCE_LENGTH
	add	rsi,	THIS_SEQUENCE_LENGTH

	; powrót z podprocedury
	jmp	console_sequence.end

;-------------------------------------------------------------------------------
.terminal_cursor_position:
	%strlen	THIS_SEQUENCE_LENGTH STATIC_SEQUENCE_CURSOR

	; rozmiar sekwencji prawidłowy?
	cmp	rcx,	THIS_SEQUENCE_LENGTH
	jb	console_sequence.error	; nie

	; sekwencja zakończona poprawnie?
	cmp	byte [rsi + THIS_SEQUENCE_LENGTH - STATIC_BYTE_SIZE_byte],	"]"
	jne	console_sequence.error	; nie

	; pobierz pozycję na osi X
	movzx	eax,	word [rsi + 0x05]
	cmp	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.width_char]	; poza obszarem?
	jb	.terminal_cursor_poistion_x_ok	; nie

	; koryguj pozyję na ostatnią kolumnę terminala
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.width_char]
	dec	eax

.terminal_cursor_poistion_x_ok:
	; zachowaj pozycję kursora na osi X
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.x],	eax

	; pobierz pozycję na osi Y
	movzx	eax,	word [rsi + 0x05 + STATIC_WORD_SIZE_byte]
	cmp	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.height_char]	; poza obszarem?
	jb	.terminal_cursor_poistion_y_ok	; nie

	; koryguj pozyję na ostatni wiersz terminala
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.height_char]
	dec	eax

.terminal_cursor_poistion_y_ok:
	; zachowaj pozycję kursora na osi X
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y],	eax

	; zamknij obsługę sekwencji
	sub	rcx,	THIS_SEQUENCE_LENGTH
	add	rsi,	THIS_SEQUENCE_LENGTH

	; zaktualizuj pozycję kursora tekstowego w konsoli
	call	library_terminal_cursor_set

	; powrót z podprocedury
	jmp	console_sequence.end

;-------------------------------------------------------------------------------
.terminal_cursor_visibility:
	; włączyć kursor?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x05],	"0"
	je	.terminal_cursor_visibility_hide	; tak

	; wyłączyć kursor?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x05],	"1"
	je	.terminal_cursor_visibility_show	; tak

	; zapamiętać pozycję?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x05],	"2"
	je	.terminal_cursor_visibility_remember	; tak

	; przywrócić pozycję?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x05],	"3"
	je	.terminal_cursor_visibility_restore	; tak

	; odblokować kursor? (wymusić włączenie)
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x05],	"4"
	je	.terminal_cursor_visibility_reset	; tak

	; przesunąć kursor o pozycję w górę?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x05],	"C"
	je	.terminal_cursor_visibility_move_up	; tak

	; przesunąć kursor o pozycję w dół?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x05],	"D"
	je	.terminal_cursor_visibility_move_down	; tak

	; przesunąć kursor o pozycję w lewo?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x05],	"E"
	je	.terminal_cursor_visibility_move_left	; tak

	; przesunąć kursor o pozycję w prawo?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x05],	"F"
	je	.terminal_cursor_visibility_move_right	; tak

	; nie rozpoznano sekwencji lub uszkodzona
	jmp	console_sequence.error

.terminal_cursor_visibility_end:
	; przetworzono sekwencję
	sub	rcx,	0x07
	add	rsi,	0x07

	; powrót z podprocedury
	jmp	console_sequence.end

;-------------------------------------------------------------------------------
.terminal_cursor_visibility_reset:
	; zresetuj licznik blokady
	mov	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.lock],	STATIC_EMPTY

	; włącz kursor
	call	library_terminal_cursor_enable

	; powrót z podprocedury
	jmp	.terminal_cursor_visibility_end

;-------------------------------------------------------------------------------
.terminal_cursor_visibility_hide:
	; ukryj kursor tekstowy
	call	library_terminal_cursor_disable

	; powrót z podprocedury
	jmp	.terminal_cursor_visibility_end

;-------------------------------------------------------------------------------
.terminal_cursor_visibility_show:
	; pokaż kursor tekstowy
	call	library_terminal_cursor_enable

	; powrót z podprocedury
	jmp	.terminal_cursor_visibility_end

;-------------------------------------------------------------------------------
.terminal_cursor_visibility_remember:
	; pobierz aktualną pozycję kursora w przestrzeni terminala
	mov	rax,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor]

	; zachowaj
	mov	qword [console_terminal_cursor_position_save],	rax

	; powrót z podprocedury
	jmp	.terminal_cursor_visibility_end

;-------------------------------------------------------------------------------
.terminal_cursor_visibility_restore:
	; ukryj kursor tekstowy
	call	library_terminal_cursor_disable

	; pobierz zapamiętaną pozycję kursora
	mov	rax,	qword [console_terminal_cursor_position_save]

	; poinformuj terminal
	mov	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor],	rax
	call	library_terminal_cursor_set

	; pokaż kursor tekstowy
	call	library_terminal_cursor_enable

	; powrót z podprocedury
	jmp	.terminal_cursor_visibility_end

;-------------------------------------------------------------------------------
.terminal_cursor_visibility_move_up:
	; pobierz aktualną pozycję kursora na osi Y
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y]

	; przesuń o pozycję w górę
	dec	eax
	jns	.terminal_cursor_visibility_move_up_ok	; brak przepełnienia

	; zablokuj kursor w pierwszym wierszu
	xor	eax,	eax

.terminal_cursor_visibility_move_up_ok:
	; zachowaj nową pozycję kursora na osi Y
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y],	eax

	; powrót z podprocedury
	jmp	.terminal_cursor_visibility_moved

;-------------------------------------------------------------------------------
.terminal_cursor_visibility_move_down:
	; pobierz aktualną pozycję kursora na osi Y
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y]

	; przesuń o pozycję w dół
	inc	eax

	; kursor wyszedł poza przestrzeń terminala?
	cmp	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.height]
	jb	.terminal_cursor_visibility_move_down_ok	; nie

	; brak przesunięcia kursora w przestrzeni terminala

	; przewiń zawartość terminala o linię w górę
	call	library_terminal_scroll

	; powrót z podprocedury
	jmp	.terminal_cursor_visibility_end

.terminal_cursor_visibility_move_down_ok:
	; zachowaj nową pozycję kursora na osi Y
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y],	eax

	; powrót z podprocedury
	jmp	.terminal_cursor_visibility_moved

;-------------------------------------------------------------------------------
.terminal_cursor_visibility_move_left:

	; powrót z podprocedury
	jmp	.terminal_cursor_visibility_end
;-------------------------------------------------------------------------------
.terminal_cursor_visibility_move_right:

	; powrót z podprocedury
	jmp	.terminal_cursor_visibility_end

;-------------------------------------------------------------------------------
.terminal_cursor_visibility_moved:
	; ustaw kursor na pozycji
	call	library_terminal_cursor_set

	; powrót z podprocedury
	jmp	.terminal_cursor_visibility_end
