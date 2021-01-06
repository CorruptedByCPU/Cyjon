;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	qword [soler.soler_fpu_fraction] - liczba całkowita
; wyjście:
;	dword [soler_fpu_float_pointer] - ilość cyfr po przecinku
;	qword [soler_fpu_float_result] - wartość zmiennoprzecinkowa
soler_fpu_fraction_to_float:
	finit	; reset koprocesora
	fld1	; st2
	fild	qword [soler_fpu_precision_digit]	; st1
	fild	qword [soler_fpu_fraction]	; st0

	; zresetuj ilość miejsc po przecinku
	mov	dword [soler_fpu_float_pointer],	STATIC_EMPTY

.loop:
	; zamień liczbę w ułamek
	fdiv	st0,	st1	; div	st1
	inc	dword [soler_fpu_float_pointer]	; ilość cyfr po przecinku
	fcomi	st0,	st2	; cmp	st0,	st2
	ja	.loop	; przeliczaj dalej

	; zachowaj wynik operacji przekształcenia
	fstp	qword [soler_fpu_float_result]

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	qword [soler_fpu_float_result] - wartość całkowita z zmiennoprzecinkową (integer.float)
; wyjście:
;	qword [soler_fpu_fraction] - wartość całkowita z ZMIENNOPRZECINKOWEJ
soler_fpu_float_to_fraction:
	; usuń wartość całkowitą
	call	soler_fpu_float_only

	finit	; reset koprocesora
	fld	qword [soler_fpu_float_result]	; mov	st1,	qword [soler_fpu_float_result]
	fild	dword [soler_fpu_precision]	; mov	st0,	dword [soler_fpu_precision]
	fmul	; mul	st1
	fistp	qword [soler_fpu_fraction]	; mov	qword [soler_fpu_fraction],	st0

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	qword [soler_fpu_float_result] - wartość zmiennoprzecinkowa (integer.float)
; wyjście:
;	dword [soler_fpu_integer] - wartość całkowita z zmiennoprzecinkowej (integer)
soler_fpu_float_to_integer:
	finit	; reset koprocesora
	fldcw	word [soler_fpu_control]	; wczytaj flagi koprocesora z zmiennej
	fld	qword [soler_fpu_float_result]	; mov	st0,	qword [soler_fpu_float_result]
	fist	dword [soler_fpu_integer]	; mov	dword [soler_fpu_integer],	st0

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	dword [soler_fpu_integer] - wartość całkowita (integer)
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
        fild	dword [soler_fpu_integer]	; mov	st0,	dword [soler_fpu_integer]
        fsub	; sub	st1,	st0
		; mov	st0,	st1
        fstp	qword [soler_fpu_float_result]	; mov	qword [soler_fpu_float_result],	st0

	; przywróć oryginalne zmienne
	pop	qword [soler_fpu_integer]

	; powrót z procedury
	ret
