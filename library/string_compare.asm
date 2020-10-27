;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rcx - ilość znaków do porównania
;	rsi - wskaźnik do ciągu pierwszego
;	rdi - wskaźnik do ciągu drugiego
; wyjście:
;	Flaga CF - jeśli różne
library_string_compare:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

.loop:
	; załaduj znak z ciągu RSI do rejestru AL, zwieksz rejestr RSI o 1
	lodsb

	; sprawdź czy znak jest identyczny z znakiem z drugiego ciągu
	cmp	al,	byte [rdi]
	jne	.error	; różne

	; przesuń wskaźnik ciągu RDI na następną pozycję
	inc	rdi

	; kontynuuj, dopóki pozostały inne znaki do porównania
	dec	rcx
	jnz	.loop

	; flaga, sukces
	clc

	; koniec procedury
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	; macro_debug	"library_string_compare"
