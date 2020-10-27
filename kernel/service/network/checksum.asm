;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - pusty lub kontynuacja poprzedniej sumy kontrolnej
;	rcx - rozmiar przestrzeni w słowach (po 2 Bajty)
;	rdi - wskaźnik do przeliczanej przestrzeni
; wyjście:
;	ax - suma kontrolna (Little-Endian)
service_network_checksum:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdi

	; ustaw wynik wstępny
	xor	ebx,	ebx
	xchg	rbx,	rax

.calculate:
	; pobierz 2 Bajty z przeliczanej przestrzeni
	mov	ax,	word [rdi]
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Big-Endian

	; dodaj do akumulatora
	add	rbx,	rax

	; przesuń wskaźnik na następny fragment
	add	rdi,	STATIC_WORD_SIZE_byte

	; przetwórz pozostałą przestrzeń
	loop	.calculate

	; koryguj sumę kontrolną o przepełnienie
	mov	ax,	bx
	shr	ebx,	STATIC_MOVE_HIGH_TO_AX_shift
	add	rax,	rbx

	; zwróć wynik w odwrotnej notacji
	not	ax

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"service_network_checksum"

;===============================================================================
; wejście:
;	rax - pusty lub kontynuacja poprzedniej sumy kontrolnej
;	ecx - rozmiar przestrzeni w słowach (po 2 Bajty)
;	rdi - wskaźnik do przeliczanej przestrzeni
; wyjście:
;	ax - suma kontrolna (Little-Endian)
service_network_checksum_part:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdi

	xor	ebx,	ebx

.calculate:
	; pobierz 2 Bajty z przeliczanej przestrzeni
	mov	bx,	word [rdi]
	rol	bx,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Big-Endian

	; dodaj do akumulatora
	add	rax,	rbx

	; przesuń wskaźnik na następny fragment
	add	rdi,	STATIC_WORD_SIZE_byte

	; przetwórz pozostałą przestrzeń
	loop	.calculate

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"service_network_checksum_part"
