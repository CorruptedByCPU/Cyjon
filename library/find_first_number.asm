;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_LIBRARY_FFN_NUMBER_LOW		equ	0x30
VARIABLE_LIBRARY_FFN_NUMBER_HIGH	equ	0x39

; 64 bitowy kod programu
[BITS 64]

;===============================================================================
; procedura pobiera od użytkownika ciąg znaków zakończony klawiszem ENTER o sprecyzowanej długości
; IN:
;	rcx - rozmiar bufora
;	rdi - wskaźnik do bufora przechowującego znaki
; OUT:
;	CF  - 0 jeśli, ok
;	rcx - rozmiar pierwszej znalezionej liczby w znakach
;	rdx - offset do pierwszej cyfry od początku poszukiwań
;	rdi - wskaźnik bezwzględny w ciągu cyfr
;
; pozostałe rejestry zachowane
library_find_first_number:
	; zachowaj oryginalne rejestry
	push	rax

	; zapamiętaj początek wskaźnika
	mov	rdx,	rdi

.find:
	; wszystko co nie jest cyfrą
	cmp	byte [rdi],	VARIABLE_LIBRARY_FFN_NUMBER_LOW
	jb	.leave
	cmp	byte [rdi],	VARIABLE_LIBRARY_FFN_NUMBER_HIGH
	ja	.leave

	; znaleziono piwerszy znak należący do słowa
	jmp	.number

.leave:
	; przesuń wskaźnik bufora na następny znak
	inc	rdi

	; kontynuuj
	loop	.find

.number:
	; sprawdź czy w bufor coś zawiera
	cmp	rcx,	0
	je	.not_found	; jeśli pusty

	; wylicz ilość znaków na liczbę

	; zachowaj adres początku
	push	rdi

	; oblicz offset
	mov	rax,	rdi
	sub	rax,	rdx
	mov	rdx,	rax

	; wyczyść licznik
	xor	rax,	rax

.count:
	; sprawdź czy koniec słowa
	cmp	byte [rdi],	VARIABLE_LIBRARY_FFN_NUMBER_LOW
	jb	.ready
	cmp	byte [rdi],	VARIABLE_LIBRARY_FFN_NUMBER_HIGH
	ja	.ready

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
