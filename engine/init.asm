;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 32 bitowy kod jądra systemu
[BITS 32]

entry:
	; wyczyść DirectionFlag
	cld

	; ustaw wskaźnik szczytu stosu na gwarantowaną wolną przestrzeń
	; taka mała ilość wystarczy (tablica multiboot nie jest już potrzebna)
	mov	esp,	0x00001000

	; zachowaj wskaźnik do mapy trybu graficznego
	push	edi

	; tablice stronicowania tworzymy pod pełnym adresem gwarantowanej wolnej przestrzeni pamięci
	; (za tablicą wektorów przerwań 16 bitowych)
	call	stage2_paging

	; przywróć wskaźnik do mapy trybu graficznego
	pop	edi

	; załaduj globalną tablicę deskryptorów
	lgdt	[gdt_structure_64bit]

	; włącz PGE, PAE w CR4
	mov	eax,	1010100000b	; OSFXSR(bit 9), PGE(bit 7) i PAE(bit 5)
	mov	cr4,	eax

	; załaduj do CR3 adres tablicy PML4
	mov	eax,	VARIABLE_MEMORY_PAGING_ADDRESS
	mov	cr3,	eax

	; włącz w rejestrze EFER MSR tryb długi
	mov	ecx,	0xC0000080	; numer EFER MSR
	rdmsr	; odczytaj
	or	eax,	00000000000000000000000100000000b	; ustawiamy bit 7 (LME)
	wrmsr	; zapisz

	; włącz stronicowanie i zarazem tryb kompatybilności (64 bit)
	mov	eax,	cr0
	or	eax,	0x80000001	; włącz PG (bit 31) i PE (bit 0)
	mov	cr0,	eax

	; skocz do 64 bitowego kodu
	jmp	0x0008:kernel

; rozpocznij tablicę od pełnego adresu
align	0x08

gdt_specification_64bit:
	; deskryptor zerowy
	dw	0x0000	; Limit 15:0
	dw	0x0000	; Baza 15:0
	db	0x00	; Baza 23:16
	db	00000000b	; P, DPL (2 bity), 1, 1, C, R, A
	db	00000000b	; G, D, L, AVL, Limit 19:16
	db	0x00	; Baza 31:24

	; deskryptor kodu
	dw	0x0000	; ignorowany
	dw	0x0000	; ignorowany
	db	0x00	; ignorowany
	db	10011000b	; P, DPL (2 bity), 1, 1, C, ignorowany, ignorowany
	db	00100000b	; ignorowany, D, L, ignorowany, ignorowany 19:16
	db	0x00	; ignorowany

	; deskryptor danych
	dw	0x0000	; ignorowany
	dw	0x0000	; ignorowany
	db	0x00	; ignorowany
	db	10010010b	; P, ignorowany (2 bity), 1, ignorowany, ignorowany, ignorowany/bochs wymaga!!!, ignorowany
	db	00100000b	; ignorowany, D, L, ignorowany, ignorowany 19:16
	db	0x00	; ignorowany
gdt_specification_64bit_end:

gdt_structure_64bit:
	dw	gdt_specification_64bit_end - gdt_specification_64bit - 1	; rozmiar
	dd	gdt_specification_64bit	; adres
