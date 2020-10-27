;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rcx - ilość znaków w ciągu
;	bl - kod ASII separatora, jeśli 0x00 to TERMINATOR, NEW_LINE, SPACE, TAB
;	rsi - wskaźnik do ciągu
; wyjście:
;	Flaga CF - jeśli błąd
;	rbx - rozmiar pierwszego znalezionego "słowa"
;	rsi - wskaźnik bezwzględny w ciągu do odnalezionego "słowa"
library_string_word_next:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx

	; ciąg pusty?
	test	rcx,	rcx
	jz	.not_found	; tak

.find:
	; znaleziono separator?
	cmp	byte [rsi],	bl
	je	.not_found	; tak, koniec ciągu

	; koniec lini?
	cmp	byte [rsi],	STATIC_ASCII_NEW_LINE
	je	.leave

	; pomiń spacje przed słowem
	cmp	byte [rsi],	STATIC_ASCII_SPACE
	je	.leave

	; pomiń znak tabulacji przed słowem
	cmp	byte [rsi],	STATIC_ASCII_TAB
	jne	.char	; znaleziono pierwszy znak należący do słowa

.leave:
	; przesuń wskaźnik bufora na następny znak
	inc	rsi

	; szukaj dalej
	dec	rcx
	jnz	.find

	; koniec ciągu
	jmp	.not_found

.char:
	; wylicz rozmiar słowa

	; zachowaj adres początku słowa
	push	rsi

	; licznik
	xor	rax,	rax

.count:
	; znaleziono separator?
	cmp	byte [rsi],	bl
	je	.ready	; tak, koniec słowa

	; koniec lini?
	cmp	byte [rsi],	STATIC_ASCII_NEW_LINE
	je	.ready

	; sprawdź czy koniec słowa
	cmp	byte [rsi],	STATIC_ASCII_SPACE
	je	.ready

	; sprawdź czy koniec słowa
	cmp	byte [rsi],	STATIC_ASCII_TAB
	je	.ready

	; przesuń wskaźnik na następny znak w buforze polecenia
	inc	rsi

	; zwiększ licznik znaków przypadających na znalezione słowo
	inc	rax

	; zliczaj dalej
	dec	rcx
	jnz	.count

.ready:
	; przywróć adres początku słowa
	pop	rsi

	; zwróć rozmiar "słowa"
	mov	rbx,	rax

	; flaga, sukces
	clc

	; koniec
	jmp	.end

.not_found:
	; nie znaleziono słowa w ciągu znaków
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"library_string_word_next"
