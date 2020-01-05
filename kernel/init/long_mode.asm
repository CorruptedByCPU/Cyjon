;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_INIT_LONG_MODE_PML4_TABLE_address	equ	0x0000A000

KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte	equ	0x1000
KERNEL_INIT_LONG_MODE_PAGE_SIZE_2MiB_byte	equ	0x00200000

KERNEL_INIT_LONG_MODE_PAGE_FLAG_available	equ	00000001b
KERNEL_INIT_LONG_MODE_PAGE_FLAG_writeable	equ	00000010b
KERNEL_INIT_LONG_MODE_PAGE_FLAG_2MiB_size	equ	10000000b
KERNEL_INIT_LONG_MODE_PAGE_FLAG_default		equ	KERNEL_INIT_LONG_MODE_PAGE_FLAG_available | KERNEL_INIT_LONG_MODE_PAGE_FLAG_writeable

	;-----------------------------------------------------------------------
	; utwórz podstawową tablicę stronicowania dla trybu 64 bitowego
	;-----------------------------------------------------------------------

	; wyczyść wszystkie wiersze tabel
	xor	eax,	eax
	mov	ecx,	(KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte * 0x06) / 0x04	; tablica PML4, PML3 i cztery razy PML2 (1 GiB opisanej przestrzeni na każdą tablicę PML2)
	mov	edi,	KERNEL_INIT_LONG_MODE_PML4_TABLE_address
	rep	stosd

	; uzupełnij pierwszy wiersz tablicy PML4 wskazujący adres tablicy PML3 (flagi domyślne)
	mov	dword [KERNEL_INIT_LONG_MODE_PML4_TABLE_address],	KERNEL_INIT_LONG_MODE_PML4_TABLE_address + KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte + KERNEL_INIT_LONG_MODE_PAGE_FLAG_default

	; uzupełnij 4 wiersze tablicy PML3 wskazujące na adresy tablic PML2 (flagi domyślne)
	mov	dword [KERNEL_INIT_LONG_MODE_PML4_TABLE_address + KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte],	KERNEL_INIT_LONG_MODE_PML4_TABLE_address + (KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte * 0x02) + KERNEL_INIT_LONG_MODE_PAGE_FLAG_default
	mov	dword [KERNEL_INIT_LONG_MODE_PML4_TABLE_address + KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte + 0x08],	KERNEL_INIT_LONG_MODE_PML4_TABLE_address + (KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte * 0x03) + KERNEL_INIT_LONG_MODE_PAGE_FLAG_default
	mov	dword [KERNEL_INIT_LONG_MODE_PML4_TABLE_address + KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte + 0x10],	KERNEL_INIT_LONG_MODE_PML4_TABLE_address + (KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte * 0x04) + KERNEL_INIT_LONG_MODE_PAGE_FLAG_default
	mov	dword [KERNEL_INIT_LONG_MODE_PML4_TABLE_address + KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte + 0x18],	KERNEL_INIT_LONG_MODE_PML4_TABLE_address + (KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte * 0x05) + KERNEL_INIT_LONG_MODE_PAGE_FLAG_default

	; uzupełnij wszystkie wiersze tablic PML2 (flagi domyślne + każdy wpis opisuje przestrzeń fizyczną o rozmiarze 2 MiB)
	mov	eax,	KERNEL_INIT_LONG_MODE_PAGE_FLAG_default + KERNEL_INIT_LONG_MODE_PAGE_FLAG_2MiB_size	; flagi: rozmiar strony 2 MiB, zapisywalna, dostępna
	mov	ecx,	512 * 0x04	; 512 wierszy na jedną tablicę PML2
	mov	edi,	KERNEL_INIT_LONG_MODE_PML4_TABLE_address + (KERNEL_INIT_LONG_MODE_PAGE_SIZE_4KiB_byte * 0x02)

.next:
	; konfiguruj wpis
	stosd

	; przesuń wskaźnik na następny wiersz tablicy
	add	edi,	0x04	; każdy wpis ma rozmiar 8 Bajtów (tryb 64 bitowy)

	; mapuj następne 2 MiB przestrzeni pamięci fizycznej
	add	eax,	KERNEL_INIT_LONG_MODE_PAGE_SIZE_2MiB_byte

	; pozostały wiersze do uzupełnienia?
	dec	ecx
	jnz	.next	; tak

	;-----------------------------------------------------------------------
	; załaduj globalną tablicę deskryptorów dla trybu 64 bitowego
	;-----------------------------------------------------------------------
	lgdt	[kernel_init_header_gdt_64bit]

	; włącz bity NX/PAE, PGE oraz OSFXSR w rejestrze CR4
	mov	eax,	1010100000b	; NX (bit 5) - blokada wykonania kodu w stronie lub obsługa pamięci fizycznej do 64 GiB
	mov	cr4,	eax		; PGE (bit 7) - obsługa stronicowania
					; OSFXSR (bit 9) - obsługa rejestrów XMM0-15

	; załaduj do CR3 adres fizyczny tablicy PML4 jądra systemu
	mov	eax,	KERNEL_INIT_LONG_MODE_PML4_TABLE_address
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

	; skocz do 64 bitowego kodu inicjalizującego
	jmp	0x0008:kernel_init

align 0x08	; wszystkie tablice trzymamy pod pełnym adresem
kernel_init_table_gdt_64bit:
	; deskryptor zerowy
	dq	STATIC_EMPTY
	; deskryptor kodu
	dq	0000000000100000100110000000000000000000000000000000000000000000b
	; deskryptor danych
	dq	0000000000100000100100100000000000000000000000000000000000000000b
kernel_init_table_gdt_64bit_end:

kernel_init_header_gdt_64bit:
	dw	kernel_init_table_gdt_64bit_end - kernel_init_table_gdt_64bit - 0x01
	dd	kernel_init_table_gdt_64bit
