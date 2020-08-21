;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
; wejście:
;	rcx - ilość znaków ciągu
;	rsi - wskaźnik do ciągu
;	r8 - wskaźnik do właściwości terminala
console_sequence:
	; rozmiar ciągu może zawierać sekwencje?
	cmp	rcx,	STATIC_ASCII_SEQUENCE_length_min
	jb	.error	; nie

	; pierwszy znak należy do sekwencji?
	cmp	byte [rsi],	STATIC_ASCII_CARET
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

	xchg	bx,bx

.error:
	; brak obsługi sekwencji
	stc

.end:
	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
.color:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi

	; tablica kolorów
	mov	rdi,	console_table_color

	; pobierz kolor znaku
	movzx	eax,	byte [rsi + STATIC_BYTE_SIZE_byte * 0x04]

	; brak koloru znaku?
	cmp	al,	"*"
	je	.color_background_only	; tak

	; ustaw kolor znaku
	call	.color_translate
	mov	eax,	dword [rdi + rax * STATIC_DWORD_SIZE_byte]
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color],	eax

.color_background_only:
	; pobierz kolor tła
	movzx	eax,	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03]

	; brak koloru tła?
	cmp	al,	"*"
	je	.color_ready	; tak

	; ustaw kolor tła
	call	.color_translate
	mov	eax,	dword [rdi + rax * STATIC_DWORD_SIZE_byte]
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.background_color],	eax

%strlen	THIS_SEQUENCE_LENGTH STATIC_ASCII_SEQUENCE_COLOR_DEFAULT

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
	cmp	al,	STATIC_ASCII_DIGIT_9
	ja	.color_translate_hex

	; zamień na cyfrę 0-9
	sub	al,	STATIC_ASCII_DIGIT_0

	; powrót z podprocedury
	ret

.color_translate_hex:
	; zamień na literę A-F
	sub	al,	STATIC_ASCII_HIGH_CASE - (STATIC_ASCII_DIGIT_9 - STATIC_ASCII_DIGIT_0)

	; powrót z podprocedury
	ret

;-------------------------------------------------------------------------------
.terminal:
	; wyczyścić przestrzeń znakową?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"0"
	jne	.terminal_no_clear	; nie

	; wyczyść przestrzeń znakową konsoli
	call	library_terminal_clear

%strlen	THIS_SEQUENCE_LENGTH STATIC_ASCII_SEQUENCE_CLEAR

	; przetworzono sekwencję
	sub	rcx,	THIS_SEQUENCE_LENGTH
	add	rsi,	THIS_SEQUENCE_LENGTH

	; powrót z podprocedury
	jmp	console_sequence.end

.terminal_no_clear:
	; ustawić kursor na nową pozycję w przestrzeni znakowej?
	cmp	byte [rsi + STATIC_BYTE_SIZE_byte * 0x03],	"1"
	jne	.terminal_no_cursor	; nie

	xchg	bx,bx

.terminal_no_cursor:
	; nie rozpoznano polecenia
	jmp	console_sequence.error
