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

find_line_indicator:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx

	; wskaźnik poczatku dokumentu
	mov	rsi,	qword [variable_document_address_start]

	; sprawdź czy pierwsza linia
	cmp	rcx,	0
	je	.end	; adresem jest początek dokumentu

.loop:
	; pobierz znak z adresu wskaźnika, zwieksz rsi o 1
	lodsb

	; sprawdź czy znak jest nową linią
	cmp	al,	0x0A
	jne	.loop	; jeśli nie, szukaj dalej

	; znaleziono znak nowej linii, mniejsz ilość pozostałych do odnalezienia i kontynuuj szukanie
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.loop

.end:
	; przywróc oryginalne rejestry
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
