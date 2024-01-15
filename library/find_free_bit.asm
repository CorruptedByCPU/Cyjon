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

;=======================================================================
; przeszukuje sprzestrzeń pamięci od adresu w RSI do RDI za ustawionym bitem
; IN:
;	rsi - początek przestrzeni przeszukiwanej
;	rdi - koniec przestrzeni
; OUT:
;	rax - adres względny strony (bitu)
;
; pozostałe rejestry zachowane
library_find_free_bit:	
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi
	push	rsi

.szukaj:
	; sprawdź czy przeszukaliśmy już całą binarną mapę
	cmp	rsi,	rdi
	jne	.continue

	; zwróć błąd
	mov	rax,	-1

	; koniec obsługi procedury
	jmp	.end

.continue:
	; załaduj do rejestru RAX, "pakiet" 64 bitów z binarnej mapy, zwiększ rejestr RSI o 8 Bajtów
	lodsq

	; sprawdź czy pakiet zawiera, jakiekolwiek bity
	cmp	rax,	0x0000000000000000
	je	.szukaj	; brak wolnych bitów, szukaj dalej

	; znaleziono wolny bit w pakiecie
	; obliczamy numer bitu pod jakim się znajduje w pakiecie

	; skoryguj adres wskaźnika źródłowego, przesuwając go na adres przetwarzanego pakietu
	sub	rsi,	0x08

	; przeszukaj 64 bity w pakiecie/"rejestrze RAX"
	bsr	rcx,	rax

	; wyłączamy (ustawiamy na zero) znaleziony bit w pakiecie/"rejestrze RAX"
	btr	rax,	rcx

	; oraz aktualizujemy binarną mapę o zmodyfikowany pakiet
	mov	qword [rsi],	rax

	; teraz należy obliczyć numer pobranego bitu z binarnej mapy

	; wyliczamy przesunięcie wewnątrz binarnej mapy
	sub	rsi,	qword [rsp]
	; zamieniamy przesunięcie z Bajtów na bity
	shl	rsi,	3	; *8

	; tworzymy lustrzane odbicie numeru znalezionego bitu, aby prawidłowo przedstawić numer strony wewnątrz "pakietu"
	mov	rax,	63
	sub	rax,	rcx

	; zwróć sumę wyników
	add	rax,	rsi

.end:
	; przywróc oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret
