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
; procedura pobiera od użytkownika ciąg znaków zakończony klawiszem ENTER o sprecyzowanej długości
; IN:
;	rcx - maksymalna ilość znaków do pobrania
;	rdi - wskaźnik do bufora przechowującego pobrane znaki
; OUT:
;	rcx - ilość pobranych znaków od użytkownika
;	CF  - 0 jeśli, ok
;
; pozostałe rejestry zachowane
library_input:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rdi
	push	r8

	; zapamiętaj rozmiar bufora
	push	rcx

	; wyświetl zawartość bufora, jeśli istnieje
	cmp	r8,	0x0000000000000000
	je	.loop	; brak

	; wyświetl tekst
	mov	rax,	0x0101
	; ustaw licznik
	xchg	rcx,	r8
	; ustaw wskaźnik do tekstu
	xchg	rsi,	rdi
	int	0x40	; wykonaj

	; przywróć licznik na miejsce
	xchg	rcx,	r8
	; przywróć wskaźnik do bufora na miejsce
	xchg	rdi,	rsi

	; zmiejsz rozmiar dostępnego bufora o wyświetloną zawartość
	sub	rcx,	r8

	; przesuń wskaźnik pozycji bufora na konieć wyświetlonej zawartości
	add	rdi,	r8

.loop:
	; pobierz klawisz z bufora klawiatury
	mov	ax,	0x0200
	int	0x40	; wykonaj

	; pusty bufor klawiatury? sprawdź raz jeszcze
	cmp	ax,	0x0000
	je	.loop

	; klawisz backspace? zmniejsz ilość znaków przetrzymywanych w buforze polecenia o jeden i wyczyść na ekranie ostatni znak
	cmp	ax,	0x0008
	je	.key_backspace

	; klawisz enter? sprawdź czy wydano polecenie
	cmp	ax,	0x000D
	je	.key_enter

	; wciśnięto klawisz ESC?
	cmp	ax,	0x001B
	je	.key_esc

	; znak dozwolony?
	; sprawdź czy pobrany znak jest możliwy do wyświetlenia
	cmp	rax,	0x0020
	jb	.loop	; nie
	cmp	rax,	0x007F
	ja	.loop	; nie

	; sprawdź czy jest dostępne miejsce w buforze
	cmp	rcx,	0
	je	.loop	; brak miejsca

	; zapisz znak do bufora
	stosb

	; zmniejsz rozmiar dostępnego bufora
	dec	rcx

.print:
	; zachowaj licznik
	push	rcx

	; wyświetl znak
	mov	r8,	rax	; załaduj znak do wyświetlenia
	mov	ax,	0x0102	; procedura - wyświetl znak
	mov	rcx,	1	; wyświetl znak tylko raz
	int	0x40	; wykonaj

	; przywróć licznik
	pop	rcx

	; kontynuuj
	jmp	.loop

.key_enter:
	; sprawdź czy bufor zawiera znaki
	cmp	rcx,	qword [rsp]
	je	.empty	; nic nie zawiera

	; oblicz rozmiar wykorzystanego bufora
	sub	qword [rsp],	rcx
	; pobierz wynik
	pop	rcx

	; wyłącz flagę CF
	clc

	; koniec procedury
	jmp	.end

.empty:
	; włącz flagę CF
	stc

	; przywróć oryginalny rozmiar bufora
	pop	rcx

.end:
	; przywróć oryginalne rejestry
	pop	r8
	pop	rdi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret


.key_backspace:
	; sprawdź czy bufor zawiera znaki
	cmp	rcx,	qword [rsp]
	je	.loop	; jeśli nie, zignoruj klawisz

	; zwieksz rozmiar dostępnego bufora
	inc	rcx
	; cofnij wskaźnik wewnątrz bufora na poprzedni znak
	dec	rdi

	; wyświetl klawisz backspace
	jmp	.print

.key_esc:
	; użytkownik przerwał procedurę

	; przywróc oryginalny rozmiar bufora
	pop	rcx

	; włącz flagę CF
	stc

	; koniec procedury
	jmp	.end
