;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 16 Bitowy kod programu
[BITS 16]

stage2_print_16bit:
	; zachowaj oryginalne rejestry
	push	ax
	push	si

	; procedura - wyświetl znak w miejscu kursora, przesuń kursor w prawo
	mov	ah,	0x0E

.loop:
	; pobierz do AL wartość z adresu pod wskaźnikiem SI, zwiększ wskaźnik SI o 1
	lodsb

	; sprawdź czy koniec tekstu do wyświetlenia
	cmp	al,	0x00	; jeśli ZERO, zakończ
	je	.end

	; wyświetl znak na ekranie
	int	0x10

	; załaduj i wyświetl następny znak
	jmp	.loop

.end:
	; przywróć oryginalne rejestry
	pop	si
	pop	ax

	; powrót z procedury
	ret
