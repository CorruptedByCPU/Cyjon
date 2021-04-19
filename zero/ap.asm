;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;===============================================================================
; 16 bitowy kod programu rozruchowego dla procesorów logicznych ================
;===============================================================================
[BITS 16]

; pozycja kodu w przestrzeni segmentu CS
[ORG 0x1000]

boot:
	;-----------------------------------------------------------------------
	; przygotuj 32 bitowe środowisko produkcyjne
	;-----------------------------------------------------------------------

	; wyłącz przerwania
	cli

	; ustaw adres segmentu kodu (CS) na początek pamięci fizycznej
	jmp	0x0000:.repair_cs

.repair_cs:
	; ustaw adresy segmentów danych (DS), ekstra (ES) i stosu (SS) na początek pamięci fizycznej
	xor	ax,	ax
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra

	; wyłącz Direction Flag
	cld

	; załaduj globalną tablicę deskryptorów dla trybu 32 bitowego
	lgdt	[boot_header_gdt_32bit]

	; przełącz procesor w tryb chroniony
	mov	eax,	cr0
	bts	eax,	0	; włącz pierwszy bit rejestru cr0
	mov	cr0,	eax

	; skocz do 32 bitowego kodu programu rozruchowego
	jmp	long 0x0008:boot_protected_mode

;-------------------------------------------------------------------------------
align 0x10	; wszystkie tablice trzymamy pod pełnym adresem
boot_table_gdt_32bit:
	; deskryptor zerowy
	dq	0x0000000000000000
	; deskryptor kodu
	dq	0000000011001111100110000000000000000000000000001111111111111111b
	; deskryptor danych
	dq	0000000011001111100100100000000000000000000000001111111111111111b
boot_table_gdt_32bit_end:

boot_header_gdt_32bit:
	dw	boot_table_gdt_32bit_end - boot_table_gdt_32bit - 0x01
	dd	boot_table_gdt_32bit

;===============================================================================
; 32 bitowy kod programu rozruchowego dla procesorów logicznych ================
;===============================================================================
[BITS 32]

boot_protected_mode:
	; ustaw deskryptory danych, ekstra i stosu na przestrzeń danych
	mov	ax,	0x10
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra

	;-----------------------------------------------------------------------
	; załaduj globalną tablicę deskryptorów dla trybu 64 bitowego
	;-----------------------------------------------------------------------
	lgdt	[boot_header_gdt_64bit]

	; włącz bity NX/PAE, PGE oraz OSFXSR w rejestrze CR4
	mov	eax,	1010100000b	; NX (bit 5) - blokada wykonania kodu w stronie lub obsługa pamięci fizycznej do 64 GiB
	mov	cr4,	eax		; PGE (bit 7) - obsługa stronicowania
					; OSFXSR (bit 9) - obsługa rejestrów XMM0-15

	; załaduj do CR3 adres fizyczny tablicy PML4 programu rozruchowego
	mov	eax,	0x0000A000	; adres zależny od tablic stronicowania programu rozruchowego Zero
	mov	cr3,	eax

	; włącz w rejestrze EFER MSR tryb LME (bit 9)
	mov	ecx,	0xC0000080	; adres EFER MSR
	rdmsr
	or	eax,	100000000b
	wrmsr

	; włącz bity PE i PG w rejestrze cr0
	mov	eax,	cr0
	or	eax,	0x80000001	; PE (bit 0) - wyłącz tryb rzeczywisty,
	mov	cr0,	eax		; PG (bit 31) - współdzielenie tablic stronicowania

	; skocz do 64 bitowego kodu programu rozruchowego dla procesorów logicznych
	jmp	0x0008:boot_long_mode

; wszystkie tablice pod adresem wyrównanym do 0x08 Bajtów
align 0x10
boot_table_gdt_64bit:
	; deskryptor zerowy
	dq	0x0000000000000000
	; deskryptor kodu
	dq	0000000000100000100110000000000000000000000000000000000000000000b
	; deskryptor danych
	dq	0000000000100000100100100000000000000000000000000000000000000000b
boot_table_gdt_64bit_end:

boot_header_gdt_64bit:
	dw	boot_table_gdt_64bit_end - boot_table_gdt_64bit - 0x01
	dd	boot_table_gdt_64bit

;===============================================================================
; 64 bitowy kod programu rozruchowego dla procesorów logicznych ================
;===============================================================================
[BITS 64]

;===============================================================================
boot_long_mode:
	; odszukaj nagłówek "Z E R O " w całym pliku jądra systemu
	mov	rax,	"Z E R O "
	mov	esi,	0x00100000

.search:
	; przesuń wskaźnik na następną pozycję
	add	rsi,	0x08

	; powównaj pierwsze 8 komórek pamięci
	cmp	qword [rsi - 0x08],	rax

	; znaleziono nagłówek?
	jne	.search	; nie

	; ustaw tymczasowy szczyt stosu dla jądra systemu
	mov	esp,	boot	; na początek przestrzeni kodu programu rozruchowego

	; pobierz wskaźnik głównej funkcji jądra systemu
	push	qword [rsi]

	; wyczyść rejestry nie biorące udziału z procesie
	xor	eax,	eax
	xor	ecx,	ecx
	xor	esi,	esi

	; wykonaj główną procedurę jądra systemu
	ret

; koniec kodu programu rozruchowego dla procesorów logicznych
boot_end:
