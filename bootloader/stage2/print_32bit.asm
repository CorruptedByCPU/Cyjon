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
[BITS 32]

stage2_print_32bit:
	; zachowaj oryginalne rejestry
	push	eax
	push	esi
	push	edi

	; ustaw domyślny kolor czcionki
	mov	ah,	VARIABLE_COLOR_DEFAULT + VARIABLE_COLOR_BACKGROUND_DEFAULT
	; adres przestrzeni pamięci ekranu tekstowego
	mov	edi,	VARIABLE_SCREEN_TEXT_MODE_ADDRESS

.loop:
	; pobierz do AL wartość z adresu pod wskaźnikiem SI, zwiększ wskaźnik SI o 1
	lodsb

	; sprawdź czy koniec tekstu do wyświetlenia
	cmp	al,	VARIABLE_ASCII_CODE_TERMINATOR	; jeśli ZERO, zakończ
	je	.end

	; zapisz na ekranie
	stosw

	; załaduj i wyświetl następny znak
	jmp	.loop

.end:
	; przywróć oryginalne rejestry
	pop	edi
	pop	esi
	pop	eax

	; powrót z procedury
	ret
