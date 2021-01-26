;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rsi - początek przestrzeni binarnej mapy pamięci
;	rdi - koniec przestrzeni binarnej mapy pamięci
; wyjście:
;	Flaga CF - błąd, jeśli ustawiona
;	rax - bezwzględny numer znalezionego bitu
library_bit_find:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi
	push	rsi

	; wyczyść akumulator
	xor	eax,	eax

.search:
	; sprawdź czy "pakiet" zawiera, jakiekolwiek bity
	cmp	qword [rsi],	STATIC_EMPTY
	jne	.found	; znaleziono

	; sprawdź następny "pakiet"
	add	rsi,	STATIC_QWORD_SIZE_byte

	; sprawdź czy przeszukaliśmy już całą binarną mapę
	cmp	rsi,	rdi
	jne	.search	; szukaj dalej

	; flaga, błąd
	stc

	; koniec
	jmp	.end

.found:
	; todo:
	; tzcnt

	; pobierz pozycję wolnego bitu od najstarszej pozycji w słowie i wyłącz go
	bsf	rax,	qword [rsi]
	btr	qword [rsi],	rax

	; oblicz bezwzględny numer pobranego bitu
	sub	rsi,	qword [rsp]

	; zamień Bajty na bity
	shl	rsi,	STATIC_DIVIDE_BY_8_shift

	; zwróć sumę pozycji
	add	rax,	rsi

	; flaga, sukces
	clc

.end:
	; przywróc oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret
