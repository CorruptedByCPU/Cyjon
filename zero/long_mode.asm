;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

ZERO_LONG_MODE_PAGE_SIZE_bytes		equ	0x1000 * 0x06	; tablica PML4, PML3 i cztery razy PML2 (1 GiB opisanej przestrzeni na każdą tablicę PML2)

ZERO_LONG_MODE_PAGE_FLAG_available	equ	00000001b
ZERO_LONG_MODE_PAGE_FLAG_writeable	equ	00000010b
ZERO_LONG_MODE_PAGE_FLAG_2MiB_size	equ	10000000b
ZERO_LONG_MODE_PAGE_FLAG_default	equ	ZERO_LONG_MODE_PAGE_FLAG_available | ZERO_LONG_MODE_PAGE_FLAG_writeable

;===============================================================================
zero_long_mode:
	;-----------------------------------------------------------------------
	; utwórz podstawową tablicę stronicowania dla trybu 64 bitowego
	;-----------------------------------------------------------------------

	; określ pozycję tablicy PML4
	mov	edi,	dword [zero_graphics_mode_info_block_address]
	add	edi,	ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.SIZE
	call	zero_page_align_up

	; zachowaj wskaźnik początku przestrzeni
	mov	dword [zero_page_table_address],	edi

	; wyczyść wszystkie wpisy w tabelach
	xor	eax,	eax
	mov	ecx,	ZERO_LONG_MODE_PAGE_SIZE_bytes / 0x04
	rep	stosd

	; przywróć wskaźnik do tabliy PML4
	mov	edi,	dword [zero_page_table_address]

	; uzupełnij pierwszy wiersz tablicy PML4 wskazujący adres tablicy PML3 (flagi domyślne)
	mov	dword [edi],	edi
	add	dword [edi],	0x1000 + ZERO_LONG_MODE_PAGE_FLAG_default

	; uzupełnij 4 wiersze tablicy PML3 wskazujące na adresy tablic PML2 (flagi domyślne)
	mov	dword [edi + 0x1000],	edi
	add	dword [edi + 0x1000],	(0x1000 * 0x02) + ZERO_LONG_MODE_PAGE_FLAG_default
	mov	dword [edi + 0x1000 + 0x08],	edi
	add	dword [edi + 0x1000 + 0x08],	(0x1000 * 0x03) + ZERO_LONG_MODE_PAGE_FLAG_default
	mov	dword [edi + 0x1000 + 0x10],	edi
	add	dword [edi + 0x1000 + 0x10],	(0x1000 * 0x04) + ZERO_LONG_MODE_PAGE_FLAG_default
	mov	dword [edi + 0x1000 + 0x18],	edi
	add	dword [edi + 0x1000 + 0x18],	(0x1000 * 0x05) + ZERO_LONG_MODE_PAGE_FLAG_default

	; uzupełnij wszystkie wiersze tablic PML2 (flagi domyślne + każdy wpis opisuje przestrzeń fizyczną o rozmiarze 2 MiB)
	mov	eax,	ZERO_LONG_MODE_PAGE_FLAG_default + ZERO_LONG_MODE_PAGE_FLAG_2MiB_size	; flagi: rozmiar strony 2 MiB, zapisywalna, dostępna
	mov	ecx,	512 * 0x04	; 512 wierszy na jedną tablicę PML2
	add	edi,	0x1000 * 0x02	; adres pierwszej tablicy PML2

.next:
	; konfiguruj wpis
	stosd

	; przesuń wskaźnik na następny wiersz tablicy
	add	edi,	0x04	; każdy wpis ma rozmiar 8 Bajtów (tryb 64 bitowy)

	; mapuj następne 2 MiB przestrzeni pamięci fizycznej
	add	eax,	0x00200000

	; pozostały wiersze do uzupełnienia?
	dec	ecx
	jnz	.next	; tak

	;-----------------------------------------------------------------------
	; załaduj globalną tablicę deskryptorów dla trybu 64 bitowego
	;-----------------------------------------------------------------------
	lgdt	[zero_long_mode_header_gdt_64bit]

	; włącz bity NX/PAE, PGE oraz OSFXSR w rejestrze CR4
	mov	eax,	1010100000b	; NX (bit 5) - blokada wykonania kodu w stronie lub obsługa pamięci fizycznej do 64 GiB
	mov	cr4,	eax		; PGE (bit 7) - obsługa stronicowania
					; OSFXSR (bit 9) - obsługa rejestrów XMM0-15

	; załaduj do CR3 adres fizyczny tablicy PML4 programu rozruchowego
	mov	eax,	dword [zero_page_table_address]
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

	; skocz do 64 bitowego kodu programu rozruchowego
	jmp	0x0008:zero_long_mode_entry

; wszystkie tablice pod adresem wyrównanym do 0x08 Bajtów
align 0x08
zero_long_mode_table_gdt_64bit:
	; deskryptor zerowy
	dq	0x0000000000000000
	; deskryptor kodu
	dq	0000000000100000100110000000000000000000000000000000000000000000b
	; deskryptor danych
	dq	0000000000100000100100100000000000000000000000000000000000000000b
zero_long_mode_table_gdt_64bit_end:

zero_long_mode_header_gdt_64bit:
	dw	zero_long_mode_table_gdt_64bit_end - zero_long_mode_table_gdt_64bit - 0x01
	dd	zero_long_mode_table_gdt_64bit

;===============================================================================
; 64 bitowy kod programu rozruchowego ==========================================
;===============================================================================
[bits 64]

;===============================================================================
zero_long_mode_entry:
