;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; 16 bitowy kod programu rozruchowego dla procesorów logicznych ================
;===============================================================================
[BITS 16]

; pozycja kodu w przestrzeni segmentu CS
[ORG 0x8000]

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

	; skocz do 32 bitowego kodu
	jmp	long 0x0008:boot_protected_mode

;===============================================================================
; 32 bitowy kod programu rozruchowego dla procesorów logicznych ================
;===============================================================================
[BITS 32]

boot_protected_mode:
	; ustaw deskryptory danych, ekstra i stosu na przestrzeń danych
	mov	ax,	0x10
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra

	; wywołaj kod jądra systemu
	jmp	0x00100000

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

; koniec kodu programu rozruchowego dla procesorów logicznych
boot_end:
