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
	push	rcx	; zmienna lokalna - pozostały rozmiar ciągu
	push	rdx
	push	rsi
	push	r8
	push	rax
	push	1000	; precyzja do 3-go miejsca po przecinku

	; zmienne lokalne
	push	STATIC_EMPTY	; frakcja
	push	STATIC_EMPTY	; całkowita

	; odszukaj znaku ułamka w ciągu
	mov	bl,	","
	call	library_string_word_next

.next:
	; podstawa cyfry
	mov	ecx,	1

	; wynik cząstkowy
	xor	r8,	r8

.loop:
	; pobierz ostatnią cyfrę z ciągu
	movzx	eax,	byte [rsi + rbx - 0x01]
	sub	al,	STATIC_SCANCODE_DIGIT_0	; przekształć kod ASCII cyfry na wartość
	mul	rcx	; zamień na wartość z danej podstawy dla cyfry

	; dodaj do wyniku cząstkowego
	add	r8,	rax

	; zamień podstawę na dziesiątki, setki, tysiące... itd.
	mov	eax,	10
	mul	rcx
	mov	rcx,	rax

	; rozmiar pozostałego ciągu
	dec	qword [rsp + STATIC_QWORD_SIZE_byte * 0x07]

	; koniec ciągu?
	dec	rbx
	jnz	.loop	; nie, przetwarzaj dalej

	; przetworzono wartość całkowitą?
	cmp	qword [rsp],	STATIC_EMPTY
	jne	.fraction	; tak

	; zachowaj wartość całkowitą
	mov	dword [rsp],	r8d

	; przywróć rozmiar pozostałego ciągu
	mov	rbx,	qword [rsp + STATIC_QWORD_SIZE_byte * 0x07]
	dec	rbx

	; przesuń wskaźnik na wartość frakcji
	add	rsi,	qword [rsp + STATIC_QWORD_SIZE_byte * 0x07]
	inc	rsi

	; kontynuuj
	jmp	.next

.fraction:
	; zachowaj wartość frakcji
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	r8

	;-----------------------------------------------------------------------

	; wartość całkowita do zmiennoprzecinkowej
	finit	; reset koprocesora
	fild	qword [rsp]
	fst	qword [rsp]

	; wartość frakcji do zmiennoprzecinkowej
	finit	; reset koprocesora
	fld1	; st2
	fild	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02]	; st1
	fild	qword [rsp + STATIC_QWORD_SIZE_byte]	; st0

.divide:
	; zamień liczbę w ułamek
	fdiv	st0,	st1	; div	st1
	fcomi	st0,	st2	; cmp	st0,	st2
	ja	.divide	; przeliczaj dalej

	; zachowaj wynik operacji przekształcenia
	fstp	qword [rsp + STATIC_QWORD_SIZE_byte]

	; dodaj obydwie liczby zmiennoprzecinkowe
	finit	; reset koprocesora
	fld	qword [rsp + STATIC_QWORD_SIZE_byte]
	fld	qword [rsp]
	faddp	st1,	st0

	; zwróć wynik
	fstp	qword [rsp + STATIC_QWORD_SIZE_byte * 0x03]

	; zwolnij zmiwnne lokalne (całkowita i frakcja)
	add	rsp,	STATIC_QWORD_SIZE_byte * 0x02

	; przywróć oryginalne rejestry
	add	rsp,	STATIC_QWORD_SIZE_byte	; zwolnij zmienną lokalną, precyzja
	pop	rax
	pop	r8
	pop	rsi
	pop	rdx
	add	rsp,	STATIC_QWORD_SIZE_byte	; zwolnij zmienną lokalną - pozostały rozmiar ciągu
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"library_string_to_float"
