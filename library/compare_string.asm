;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 64 bitowy kod programu
[BITS 64]

;===============================================================================
; procedura porównuje dwa ciągi
; IN:
;	rcx	- ilość znaków do porównania
;	rsi	- adres ciągu pierwszego
;	rdi	- adres ciągu drugiego
; OUT:
;	CF	- 0 jeśli, ok
;
; wszystkie rejestry zachowane
library_compare_string:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

.loop:
	; załaduj znak z ciągu do rejestru al, zwieksz rejestr rsi o 1
	lodsb

	; sprawdź czy znak jest identyczny z znakiem z drugiego ciągu
	cmp	al,	byte [rdi]
	je	.ok

	; włącz flagę CF
	stc

.end:
	; przywróc oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

.ok:
	; przesuń wskaźnik rdi w drugim ciągu znaków na następną pozycję
	inc	rdi

	; kontynuuj
	loop	.loop

	; wyłącz flagę CF
	clc

	; zakończ procedurę
	jmp	.end
