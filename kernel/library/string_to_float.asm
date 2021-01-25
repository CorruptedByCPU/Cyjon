;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rcx - ilość znaków w ciągu
;	rsi - wskaźnik do ciągu
; wyjście:
;	rax - wartość zmiennoprzecinkowa
library_string_to_float:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi
	push	rax

	; ciąg pusty?
	test	rcx,	rcx
	jz	.error	; tak

	; ustaw zmienne lokalne
	push	STATIC_NUMBER_SYSTEM_decimal	; system dziesiętny
	push	STATIC_EMPTY	; frakcja
	push	STATIC_EMPTY	; całkowita

	; odszukaj znaku ułamka w ciągu
	mov	al,	","
	call	library_string_word_next
	jnc	.integer	; zamień wartość całkowitą na część ułamkową

	; zamień cały ciąg na liczbę
	call	library_string_to_integer

	; aktualizuj wartość całkowitą
	mov	qword [rsp],	rax

	; wartość całkowita do zmiennoprzecinkowej
	finit	; reset koprocesora
	fild	qword [rsp]

	; zwolnij zmienne lokalne
	add	rsp,	STATIC_QWORD_SIZE_byte * 0x03

	; zwróć wynik
	fstp	qword [rsp]

	; koniec operacji przekształcenia
	jmp	.end

.integer:
	; ilość cyfr z wartości całkowitej
	test	rbx,	rbx
	jz	.integer_empty	; brak

	; zamień cały ciąg na liczbę
	call	library_string_to_integer

	; aktualizuj wartość całkowitą
	mov	qword [rsp],	rax

.integer_empty:
	; koryguj rozmiar i wskaźnik ciągu
	inc	rbx	; separator
	sub	rcx,	rbx
	add	rsi,	rbx

.fraction:
	; domyślnie brak części ułamkowej
	xor	ebx,	ebx

	; brak cyfr w wartości frakcji?
	test	rcx,	rcx
	jz	.transform	; tak

	; zamień cały ciąg na liczbę
	mov	rbx,	rcx
	call	library_string_to_integer

	; aktualizuj wartość frakcji
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rax

.transform:
	; wartość frakcji do zmiennoprzecinkowej
	finit	; reset koprocesora
	fild	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02]	; st1 > system liczbowy
	fild	qword [rsp + STATIC_QWORD_SIZE_byte]	; st0 > frakcja

.convert:
	; zamień liczbę w ułamek
	fdiv	st0,	st1	; div	st1

	; osiągnięto rząd wielkości?
	dec	rbx
	jnz	.convert	; nie, przeliczaj dalej

	; dodaj obydwie liczby zmiennoprzecinkowe
	fild	qword [rsp]	; st0 > całkowita
	faddp	st1,	st0

	; zwolnij zmienne lokalne
	add	rsp,	STATIC_QWORD_SIZE_byte * 0x03

	; zwróć wynik
	fstp	qword [rsp]

	; koniec operacji przekształcenia
	jmp	.end

.error:
	; nie udało się poprawnie przetworzyć ciągu, zwróć "0.0"
	mov	qword [rsp],	STATIC_EMPTY

.end:
	; przywróć oryginalne rejestry
	pop	rax
	pop	rsi
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"library_string_to_float"
