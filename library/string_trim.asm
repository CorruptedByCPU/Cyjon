;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rcx	- ilość znaków w ciągu
;	rsi	- wskaźnik do ciągu
; wyjście:
;	Flaga CF - ciąg pusty
;	rcx	- ilość znaków w ciągu bez "białych" znaków
;	rsi	- wskaźnik początku ciągu bez "białych" znaków
library_string_trim:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; ciąg pusty?
	test	rcx,	rcx
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
	; przesuń wskaźnik na nastepny znak w ciągu
	inc	rsi

	; ilość znaków w ciągu
	dec	rcx
	jnz	.prefix	; przetwórz pozostałą zawartość ciągu

	; ciąg pusty
	jmp	.error

.prefix_ready:
	; przesuń wskaźnik na koniec ciągu
	add	rsi,	rcx

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
	; przesuń wskaźnik na poprzedni znak w ciągu
	dec	rsi

	; ilość znaków w ciągu
	dec	rcx
	jnz	.suffix	; przetwórz pozostałą zawartość ciągu

	; ciąg pusty
	jmp	.error

.suffix_ready:
	; ustaw wskaźnik na początek ciągu bez "białych" znaków
	sub	rsi,	rcx

	; zwróć właściwości nowego ciągu
	mov	qword [rsp],	rsi
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rcx

	; flaga, sukces
	clc

	; koniec procedury
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret

	; macro_debug	"library_string_trim"
