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
; procedura wyszukuje pierwszego ciągu znaków zakończonego znakiem SPACJI, TABULATORA lub ENTERA
; IN:
;	rcx - rozmiar bufora
;	rdi - wskaźnik do bufora
; OUT:
;	CF  - 0 jeśli, ok
;	rcx - rozmiar pierwszego znalezionego "słowa"
;	rdi - wskaźnik bezwzględny w ciągu do znalezionego słowa
;
; pozostałe rejestry zachowane
library_find_first_word:
	; zachowaj oryginalne rejestry
	push	rax

.find:
	; pomiń spacje przed słowem
	cmp	byte [rdi],	VARIABLE_ASCII_CODE_SPACE
	je	.leave

	; pomiń znak tabulacji
	cmp	byte [rdi],	VARIABLE_ASCII_CODE_TAB
	je	.leave

	; znaleziono piwerszy znak należący do słowa
	jmp	.char

.leave:
	; przesuń wskaźnik bufora na następny znak
	inc	rdi

	; kontynuuj
	loop	.find

.char:
	; sprawdź czy w bufor coś zawiera
	cmp	rcx,	0
	je	.not_found	; jeśli pusty

	; oblicz rozmiar słowa

	; zachowaj adres początku słowa
	push	rdi

	; wyczyść licznik
	xor	rax,	rax

.count:
	; sprawdź czy koniec słowa
	cmp	byte [rdi],	VARIABLE_ASCII_CODE_SPACE
	je	.ready

	; sprawdź czy koniec słowa
	cmp	byte [rdi],	VARIABLE_ASCII_CODE_TAB
	je	.ready

	; nieoczekiwany koniec ciągu?
	cmp	byte [rdi],	VARIABLE_ASCII_CODE_TERMINATOR
	je	.ready

	; przesuń wskaźnik na następny znak w buforze polecenia
	inc	rdi

	; zwiększ licznik znaków przypadających na znalezione polecenie
	inc	rax

	; zliczaj dalej
	loop	.count

.ready:
	; ustaw rozmiar słowa w znakach
	mov	rcx,	rax

	; przywróć adres początku słowa
	pop	rdi

	; ustaw flagę
	clc

	; koniec
	jmp	.end

.not_found:
	; nie znaleziono słowa w ciągu znaków
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret
