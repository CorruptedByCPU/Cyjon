;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
soler_show:
	; pierwsza wartość zatwierdzona?
	cmp	r11b,	STATIC_FALSE
	je	.end	; nie

	; rozmiar ciągu wartości
	xor	edx,	edx

	; wskaźnik początku ciągu wartości
	mov	rdi,	soler_window.element_label_value_string

	; pobierz wynik operacji
	mov	rax,	qword [soler_value_first]

	; wyodrębnij wartość całkowitą z zmiennoprzecinkowej
	mov	qword [soler_fpu_float_result],	rax
	call	soler_fpu_float_to_integer
	mov	qword [soler_fpu_precision],	4	; maksymalna ilość miejsc po przecunku
	call	soler_fpu_float_to_fraction	; oraz frakcji

	; wartość ujemna?
	bt	rax,	STATIC_QWORD_BIT_sign
	jnc	.unsigned	; nie

	; wstaw znak "-" do ciągu wartości
	mov	byte [soler_window.element_label_value_length],	STATIC_BYTE_SIZE_byte
	mov	byte [soler_window.element_label_value_string],	STATIC_SCANCODE_MINUS

	; przesuń wskaźnik ciągu wartości na następną pozycję oraz jego rozmiar
	inc	rdx
	inc	rdi

.unsigned:
	; załaduj wartość całkowitą części ułamka
	mov	rax,	qword [soler_fpu_integer]
	mov	bl,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx
	call	library_integer_to_string

	; przesuń wskaźnik ciągu wartości za całkowitą część ułamka oraz zlicz rozmiar
	add	rdx,	rcx
	add	rdi,	rcx

	; frakcja ułamka jest pusta?
	cmp	qword [soler_fpu_fraction],	STATIC_EMPTY
	je	.ready	; tak

	; wstaw znak "," do ciągu wartości
	mov	byte [rdi],	","

	; przesuń wskaźnik ciągu wartości na następną pozycję oraz jego rozmiar
	inc	rdx
	inc	rdi

	; załaduj wartość całkowitą części ułamka
	mov	rax,	qword [soler_fpu_fraction]
	mov	bl,	STATIC_NUMBER_SYSTEM_decimal
	mov	rcx,	qword [soler_fpu_precision]
	mov	dl,	STATIC_SCANCODE_DIGIT_0
	call	library_integer_to_string

	; przesuń wskaźnik ciągu wartości za całkowitą część ułamka oraz zlicz rozmiar
	add	rdx,	rcx
	add	rdi,	rcx

.ready:


.end:
	; powrót z peocedury
	ret
