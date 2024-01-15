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

key_delete:
	; sprawdź czy jesteśmy na końcu dokumentu
	mov	rcx,	qword [cursor_position]
	cmp	rcx,	qword [document_chars_count]
	je	start.loop	; nie ma czego usunąć

	; usuń znak z aktualnej pozycji kursora wewnątrz dokumentu i przesuń pozostałą zawartość dokumentu o jeden znak wstecz

	; ustaw kierunek kopiowania
	mov	rdi,	qword [document_address_start]
	add	rdi,	qword [cursor_position]

	; ustaw źródło kopiowania
	mov	rsi,	rdi
	; skopiuj następny znak [rsi] w miejsce poprzedniego [rdi]
	inc	rsi

	; sprawdź czy znak nowej linii
	cmp	byte [rdi],	0x0A
	je	start.loop	; brak obsługi (brak obsługi linii większych niż 79 znaków)

	; oblicz ilość znaków do przesunięcia
	mov	rcx,	qword [document_chars_count]
	sub	rcx,	qword [cursor_position]

.loop:
	; pobierz znak "następny", zwiększ rsi o 1
	lodsb
	; załaduj w "aktualne" miejsce,	 zwieksz rdi o 1
	stosb

	; kontynuuj dla pozostałych znaków, mniejsz rcx o 1
	loop	.loop

	; koryuj ilość znaków w dokumencie
	dec	qword [document_chars_count]
	; koryguj ilośc znaków w linii
	dec	qword [line_chars_count]

	; wyświetl zmodyfikowaną zawartość dokumentu
	call	print

	; aktualizuj pozycje kursora
	call	set_cursor

	; powrót z funkcji
	jmp	start.loop
