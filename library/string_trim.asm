;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; wejście:
;	rbx	- ilość znaków w buiforze
;	rsi	- wskaźnik do buifora
; wyjście:
;	Flaga CF - buifor pusty
;	rbx	- ilość znaków w buforze bez "białych" znaków lub wartość nieokreślona gdy flaga CF
;	rsi	- wskaźnik początku bufora bez "białych" znaków lub wartość nieokreślona gdy flaga CF
library_string_trim:
	; ciąg pusty?
	test	rbx,	rbx
	jz	.error	; tak

.prefix:
	; spacja?
	cmp	byte [rsi],	STATIC_ASCII_SPACE
	je	.prefix_found	; tak

	; tabulator?
	cmp	byte [rsi],	STATIC_ASCII_TAB
	je	.prefix_found	; tak

	; pusty znak?
	cmp	byte [rsi],	STATIC_EMPTY
	jne	.prefix_ready	; nie

.prefix_found:
	; przesuń wskaźnik na nastepny znak w buforze
	inc	rsi

	; ilość znaków w buforze
	dec	rbx
	jnz	.prefix	; przetwórz pozostałą zawartość bufora

	; bufor pusty
	jmp	.error

.prefix_ready:
	; przesuń wskaźnik na koniec bufora
	add	rsi,	rbx

.suffix:
	; spacja?
	cmp	byte [rsi - STATIC_BYTE_SIZE_byte],	STATIC_ASCII_SPACE
	je	.suffix_found	; tak

	; tabulator?
	cmp	byte [rsi - STATIC_BYTE_SIZE_byte],	STATIC_ASCII_TAB
	je	.suffix_found	; tak

	; pusty znak?
	cmp	byte [rsi - STATIC_BYTE_SIZE_byte],	STATIC_EMPTY
	jne	.suffix_ready	; nie

.suffix_found:
	; przesuń wskaźnik na poprzedni znak w buforze
	dec	rsi

	; ilość znaków w buforze
	dec	rbx
	jnz	.suffix	; przetwórz pozostałą zawartość bufora

	; bufor pusty
	jmp	.error

.suffix_ready:
	; ustaw wskaźnik na początek bufora bez znaków "białych"
	sub	rsi,	rbx

	; flaga, sukces
	clc

	; koniec procedury
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; powrót z procedury
	ret
