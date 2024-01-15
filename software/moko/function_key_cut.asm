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

key_function_cut:
	; sprawdź czy dokument zawiera treść
	cmp	qword [document_chars_count],	0
	je	start.loop	; jeśli nie, koniec obsługi skrótu

	; ustaw wskaźnik pozycji kursora na początek aktualnej linii
	mov	rdi,	qword [document_address_start]
	add	rdi,	qword [cursor_position]
	movzx	rcx,	byte [cursor_yx]
	sub	rdi,	rcx

	; zapamiętaj nową pozycje kursora w dokumencie
	sub	qword [cursor_position],	rcx

	; ilość znaków w linii do usunięcia z dokumentu
	mov	rcx,	qword [line_chars_count]

	; zapamiętaj adres początku nowej linii
	push	rdi

	; sprawdź czy na końcu linii znajduje się znak nowej linii
	cmp	byte [rdi + rcx], 0x0A
	jne	.no_new_line

	; + znak nowej linii
	inc	rcx

.no_new_line:
	; zachowaj ilość znaków do usunięcia
	push	rcx

	; ustaw wskaźnik źródłowy
	mov	rsi,	rdi
	add	rsi,	rcx

	; usuń określoną ilość znaków
	mov	rcx,	qword [document_chars_count]
	; pomiń zawartość dokumentu przed usuwaną linią
	sub	rcx,	qword [cursor_position]
	; pomiń ilośc znaków z rozmiaru usuwanej linii
	sub	rcx,	qword [rsp]

	; spawdź czy brak dokumentu za usuwaną linią
	cmp	rcx,	0
	je	.leave	; jeśli tak, nie kopiuj

.loop:
	; pobierz znak zza linii usuwanej
	lodsb
	; zapisz w miejsce bierzącej
	stosb

	; kontynuuj dla pozostałych znaków
	loop	.loop

.leave:
	; przywróć ilość usuniętych znaków
	pop	rcx

	; zmniejsz rozmiar dokumentu o ilość usuniętych znaków
	sub	qword [document_chars_count],	rcx

	; wyczyść pozostałości za dokumentem
	xor	rax,	rax
	rep	stosb	; wykonaj

	; przywróć adres początku nowej linii
	pop	rsi

	; oblicz rozmiar nowej linii
	call	count_chars_in_line

	; zapamiętaj ilość znaków w linii gdzie przebywa kursor
	mov	qword [line_chars_count],	rcx

	; koryguj ilość linii w dokumencie
	cmp	qword [document_lines_count],	0
	je	.end

	; aktualizuj ilość linii w dokumencie
	dec	qword [document_lines_count]

.end:
	; aktualizuj zawartość ekranu
	call	print

	; zachowaj informacje o zmodyfikowanym dokumencie
	mov	byte [semaphore_modified],	0x01

	; ustaw kursor na poczatku linii
	mov	byte [cursor_yx],	0
	; aktualizuj pozycje kursora
	call	set_cursor

	; koniec obsługi skrótu
	jmp	start.loop
