;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 64 Bitowy kod programu
[BITS 64]

count_chars_in_line:
	; zachowaj oryginalne rejestry
	push	rsi

	; wyzeruj licznik
	xor	rcx,	rcx

.loop:
	; sprawdź czy koniec dokumentu
	cmp	byte [rsi],	0x00
	je	.end

	; sprawdź czy koniec linii
	cmp	byte [rsi],	0x0A
	je	.end

	; zwiększ ilość znaków przechowywanych w linii
	inc	rcx

	; przesuń wskaźnik na następny znak
	inc	rsi

	; kontynuuj obliczenia
	jmp	.loop

.end:
	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret
