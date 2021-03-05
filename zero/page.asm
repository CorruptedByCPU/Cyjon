;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; 16 bitowy kod głównego programu rozruchowego =================================
;===============================================================================
[bits 32]

;===============================================================================
; wejście:
;	edi - adres w przestrzeni logicznej
; wyjście:
;	edi - adres wyrównany do pełnej strony
zero_page_align_up:
	; utwórz zmienną lokalną
	push	edi

	; usuń młodszą część adresu
	and	edi,	0xF000

	; sprawdź czy adres jest identyczny z zmienną lokalną
	cmp	edi,	dword [esp]
	je	.end	; jeśli tak, koniec

	; przesuń adres o jedną ramkę do przodu
	add	edi,	0x1000
.end:
	; usuń zmienną lokalną
	add	esp,	0x04

	; powrót z procedury
	ret
