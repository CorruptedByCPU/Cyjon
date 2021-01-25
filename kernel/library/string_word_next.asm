;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	al - kod ASII separatora
;	rcx - rozmiar ciągu w Bajtach
;	rsi - wskaźnik do ciągu
; wyjście:
;	Flaga CF - jeśli nie znaleziono separatora
;	rbx - rozmiar ciągu do pierwszego separatora
;	lub rbx = rcx jeśli Flaga CF
library_string_word_next:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; licznik
	xor	ebx,	ebx

.search:
	; koniec ciągu?
	dec	rcx
	js	.not_found	; tak

	; znaleziono separator?
	cmp	byte [rsi],	al
	je	.end	; tak, koniec fragmentu ciągu

	; przesuń wskaźnik na następny znak w buforze polecenia
	inc	rsi

	; zwiększ licznik znaków przypadających na znalezione słowo
	inc	rbx

	; zliczaj dalej
	jmp	.search

.not_found:
	; nie znaleziono słowa w ciągu znaków
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"library_string_word_next"
