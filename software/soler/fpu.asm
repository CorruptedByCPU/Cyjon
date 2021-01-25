;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	qword [soler_fpu_precision] - ilość miejsc po przecinku
;	qword [soler_fpu_fraction] - wartość frakcji w formie całkowitej
; wyjście:
;	qword [soler_fpu_float_result] - wartość zmiennoprzecinkowa
soler_fpu_fraction_to_float:
	finit	; reset koprocesora
	fld1	; st2
	fild	qword [soler_fpu_precision_value]	; st1
	fild	qword [soler_fpu_fraction]	; st0

.loop:
	; przeliczać na ułamek?
	dec	qword [soler_fpu_precision]
	js	.end	; nie
	jz	.ready	; koniec

	; zamień liczbę w ułamek
	fdiv	st0,	st1	; div	st1
	jmp	.loop	; kontynuuj

.ready:
	; zachowaj wynik operacji przekształcenia
	fstp	qword [soler_fpu_float_result]

.end:
	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	qword [soler_fpu_precision] - ilość cyfr do zinterpretowania
;	qword [soler_fpu_float_result] - wartość całkowita z zmiennoprzecinkową (integer.float)
; wyjście:
;	qword [soler_fpu_fraction] - wartość całkowita z ZMIENNOPRZECINKOWEJ
soler_fpu_float_to_fraction:
	; zachowaj oryginalne rejestry/zmienne
	push	rcx

	; pobierz rozmiar precyzji
	mov	rcx,	qword [soler_fpu_precision]

	; usuń wartość całkowitą
	call	soler_fpu_float_only

	finit	; reset koprocesora
	fild	qword [soler_fpu_precision_value]	; mov	st1,	qword [soler_fpu_precision]
	fld	qword [soler_fpu_float_result]	; mov	st0,	qword [soler_fpu_float_result]

.loop:
	; przeliczać na ułamek?
	dec	rcx
	js	.end	; nie
	jz	.ready	; koniec

	; zamień ułamek w liczbę
	fmul	st0,	st1
	jmp	.loop	; kontynuuj

.ready:
	fistp	qword [soler_fpu_fraction]	; mov	qword [soler_fpu_fraction],	st0

.end:
	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	qword [soler_fpu_float_result] - wartość zmiennoprzecinkowa (integer.float)
; wyjście:
;	qword [soler_fpu_integer] - wartość całkowita z zmiennoprzecinkowej (integer)
soler_fpu_float_to_integer:
	finit	; reset koprocesora
	fldcw	word [soler_fpu_control]	; wczytaj flagi koprocesora z zmiennej
	fld	qword [soler_fpu_float_result]	; mov	st0,	qword [soler_fpu_float_result]
	fistp	qword [soler_fpu_integer]	; mov	qword [soler_fpu_integer],	st0

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	qword [soler_fpu_integer] - wartość całkowita (integer)
; wyjście:
;	qword [soler_fpu_float_result] - wartość zmiennoprzecinkowa (integer.0)
soler_fpu_integer_to_float:
	finit	; reset koprocesora
	fild	qword [soler_fpu_integer]
	fst	qword [soler_fpu_float_result]

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	qword [soler_fpu_float_result] - wartość całkowita z zmiennoprzecinkową
; wyjście:
;	qword [soler_fpu_float_result] - wartość zmiennoprzecinkowa (0.float)
soler_fpu_float_only:
	; zachowaj oryginalne zmienne
	push	qword [soler_fpu_integer]

	; zachowaj osobno wartość całkowitą z zmiennoprzecinkowej
	call	soler_fpu_float_to_integer

	finit	; reset koprocesora
	fld	qword [soler_fpu_float_result]	; mov	st1,	qword [soler_fpu_float_result]
        fisub	dword [soler_fpu_integer]	; sub	st0, dword [soler_fpu_integer]
		; mov	st0,	st1
        fstp	qword [soler_fpu_float_result]	; mov	qword [soler_fpu_float_result],	st0

	; przywróć oryginalne zmienne
	pop	qword [soler_fpu_integer]

	; powrót z procedury
	ret
