;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; wejście:
;	ecx - rozmiar ciągu w znakach
;	rsi - wskaźnik do ciągu
kernel_panic:
	; kolor komunikatu: jasno-czerwony
	mov	ah,	0x0C

	; ustaw wskaźnik na początek przestrzeni pamięci karty graficznej trybu tekstowego
	mov	edi,	0x000B8000

.loop:
	; pobierz znak z ciągu
	lodsb

	; wyświetl
	stosw

	; koniec ciągu?
	dec	ecx
	jnz	.loop	; nie, wyświetl resztę

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$
