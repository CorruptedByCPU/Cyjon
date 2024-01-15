;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 16 Bitowy kod programu
[BITS 16]

stage2_memory_map:
	; zachowaj oryginalny rejestr
	push	di
	; zachowaj adres segmentu ekstra
	push	es

	; utwórz pod adresem 0x0000:0x0500, mapę pamięci z procedury 0xE820, przerwania 0x15
	xor	ax,	ax
	mov	es,	ax
	mov	di,	0x0500

	; przygotowanie rejestrów pod procedurę mapowania
	xor	ebx,	ebx	; wyczyść
	mov	edx,	0x534D4150	; tekst "SMAP", specjalna wartość wymagana przez procedurę

.loop:
	; procedura przerwania 0x15
	mov	eax,	0xE820
	mov	ecx,	24	; rozmiar rekordu opisującego daną przestrzeń pamięci
	mov	dword [es:di + 20],	0x0001	; wsparcie dla ACPI 3.0+
	int	0x15	; wykonaj

	; jeśli wystąpi błąd podczas mapowania pamięci, program rozruchowy kończy działanie!
	jc	.error

	; wszystko jest w porządku, więc przesuwamy wskaźnik na następne miejsce (rekord)
	add	di,	24

	; jeśli bx jest równe zero, procedura zakończyła mapować całą przestrzeń pamięci fizycznej
	cmp	bx,	0x0000
	jne	.loop	; kontynuuj

	; utwórz pusty rekord, określający koniec mapy pamięci
	xor	al,	al
	rep	stosb	; wykonaj

	; przywróc adres segmentu ekstra
	pop	es
	; przywróć oryginalny rejestr
	pop	di

	; powrót z procedury
	ret

	; powrót z procedury
	ret

.error:
	; przywróc adres segmentu ekstra
	pop	es
	; przywróć oryginalny rejestr
	pop	di

	; brak możliwości utworzenia mapy pamięci, koniec
	mov	si,	text_no_memory
	call	stage2_print_16bit

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

text_no_memory		db	"An error occurred while performing memory map!", VARIABLE_ASCII_CODE_TERMINATOR
