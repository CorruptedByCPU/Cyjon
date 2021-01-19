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

	; pobierz wynik operacji
	mov	rax,	qword [soler_value_first]

	; wyodrębnij wartość całkowitą z zmiennoprzecinkowej
	mov	qword [soler_fpu_float_result],	rax
	call	soler_fpu_float_to_integer
	call	soler_fpu_float_to_fraction	; oraz frakcji

	

.end:
	; powrót z peocedury
	ret
