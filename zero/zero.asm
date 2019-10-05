;================================================================================
; Copyright (C) by Blackend.dev
;================================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty itp.
	;-----------------------------------------------------------------------
	%include	"zero/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
; 16 bitowy kod programu rozruchowego ==========================================
;===============================================================================
[BITS 16]

; pozycja kodu w przestrzeni segmentu CS
[ORG STATIC_ZERO_address]

zero:
	;-----------------------------------------------------------------------
	; przygotuj 16 bitowe środowisko produkcyjne
	;-----------------------------------------------------------------------

	; wyłącz przerwania (modyfikujemy rejestry segmentowe)
	cli

	; ustaw adres segmentu kodu (CS) na początek pamięci fizycznej
	jmp	0x0000:.repair_cs

.repair_cs:
	; ustaw adresy segmentów danych (DS), ekstra (ES) i stosu (SS) na początek pamięci fizycznej
	xor	ax,	ax
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra
	mov	ss,	ax	; segment stosu

	; ustaw wskaźnik szczytu stosu na gwarantowaną wolną przestrzeń pamięci
	mov	sp,	STATIC_ZERO_stack

	; wyłącz Direction Flag
	cld

	;-----------------------------------------------------------------------
	; wyłącz przerwanie IRQ0 na kontrolerze PIT, jądro systemu skonfiguruje i uruchomi wg. własnych potrzeb
	;-----------------------------------------------------------------------
	mov	al,	STATIC_EMPTY	; Channel (00b), Access (11b), Operating (000b), Binary Mode (0b)
	out	DRIVER_PIT_PORT_command,	al

	; włącz "pozostałe" przerwania
	sti

	;=======================================================================
	; Program rozruchowy Zero przeznaczony jest tylko dla środowisk zwirtualizowanych!
	; Nie została poprawnie zaimplementowana obsługa linii A20 dla sprzętu fizycznego.
	;=======================================================================

	;-----------------------------------------------------------------------
	; odblokuj linię A20 za pomocą fukcji BIOSu
	;-----------------------------------------------------------------------
	mov	ax,	0x2401
        int	0x15

	;-----------------------------------------------------------------------
	; odblokuj linię A20 za pomocą Fast A20
	;-----------------------------------------------------------------------
	in	al,	0x92
        or	al,	2
        out	0x92,	al

	;-----------------------------------------------------------------------
	; wyczyść ekran inicjując ponownie tryb tekstowy (80x25 znaków)
	;-----------------------------------------------------------------------
	mov	ax,	0x0003
	int	0x10

	;-----------------------------------------------------------------------
	; wczytaj kod jądra systemu do przestrzeni pamięci fizycznej
	;-----------------------------------------------------------------------
	mov	ah,	0x42
	mov	si,	zero_table_disk_address_packet
	int	0x13

	; komunikat błędu: błąd odczytu z nośnika
	mov	si,	STATIC_ZERO_ERROR_device

	; opracja odczytu wykonana poprawnie?
	jc	zero_panic	; nie

	;-----------------------------------------------------------------------
	; przygotuj mapę pamięci za pomocą funkcji BIOSu
	; http://www.ctyme.com/intr/rb-1741.htm
	;-----------------------------------------------------------------------
	xor	ebx,	ebx	; pozpocznij mapowanie od początku przestrzeni fizycznej pamięci
	mov	edx,	0x534D4150	; ciąg znaków "SMAP", specjalna wartość wymagana przez procedurę

	; komunikat błędu: błąd mapowania przestrzeni pamięci
	mov	si,	STATIC_ZERO_ERROR_memory

	; utwórz mapę pamięci pod fizycznym adresem 0x0000:0x1000
	mov	edi,	STATIC_ZERO_memory_map

.memory:
	; rozmiar wpisu
	mov	eax,	0x14
	stosd

	; pobierz informacje o przestrzeni pamięci
	mov	eax,	0xE820	; funkcja Get System Memory Map
	mov	ecx,	0x14	; rozmiar wiersza w Bajtach, generowanej tablicy
	int	0x15

	; błąd podczas generowania?
	jc	zero_panic	; tak

	; przesuń wskaźnik do następnego wiersza
	add	edi,	0x14

	; koniec wierszy generowanej tablicy?
	test	ebx,	ebx
	jnz	.memory	; nie

	;-----------------------------------------------------------------------
	; wyłącz wszystkie przerwania na kontrolerze PIC, jądro systemu skonfiguruje i uruchomi wg. własnych potrzeb
	;-----------------------------------------------------------------------
	mov	al,	0xFF
	out	DRIVER_PIC_PORT_SLAVE_data,	al	; Slave
	out	DRIVER_PIC_PORT_MASTER_data,	al	; Master

	; wyłącz przerwania, jeśli program rozruchowy jest w trybie 16 bitowym
	; zostaną one przywrócone
	cli

;===============================================================================
; jeśli program rozruchowy jest w trybie 16 bitowym
;===============================================================================
%if STATIC_ZERO_bit_mode = 16
	; ustaw segmenty danych i ekstra na przestrzeń kodu/danych jądra systemu
	mov	ax,	STATIC_ZERO_kernel_address
	mov	ds,	ax
	mov	es,	ax

	; włącz przerwania
	sti

	; zwróć informacje o adresie tablicy mapy pamięci
	mov	ebx,	STATIC_ZERO_memory_map

	; wywołaj kod jądra systemu
	jmp	STATIC_ZERO_kernel_address:0x0000
%endif

	;-----------------------------------------------------------------------
	; tryb programu rozruchowego nie jest 16 bitowy
	;-----------------------------------------------------------------------

	; załaduj globalną tablicę deskryptorów dla trybu 32 bitowego
	lgdt	[zero_header_gdt_32bit]

	; przełącz procesor w tryb chroniony
	mov	eax,	cr0
	bts	eax,	0	; włącz pierwszy bit rejestru cr0
	mov	cr0,	eax

	; skocz do 32 bitowego kodu
	jmp	long 0x0008:zero_protected_mode

;-------------------------------------------------------------------------------
; wejście:
;	si - kod błędu w postaci znaku ASCII
zero_panic:
	; ustaw segment danych (DS) na przestrzeń pamięci ekranu trybu tekstowego
	mov	ax,	0xB800
	mov	ds,	ax

	; wyświetl kod błędu
	mov	word [ds:0x0000],	si

	; zatrzymaj dalsze wykonywanie kodu programu rozruchowego
	jmp	$

;===============================================================================
; 32 bitowy kod programu rozruchowego ==========================================
;===============================================================================
[BITS 32]

zero_protected_mode:
	; ustaw deskryptory danych, ekstra i stosu na przestrzeń danych
	mov	ax,	0x10
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra
	mov	ss,	ax	; segment stosu

	;-----------------------------------------------------------------------
	; utwórz nagłówek Multiboot (wersja 0.6.96)
	;-----------------------------------------------------------------------

	; wylicz rozmiar utworzonej mapy pamięci w Bajtach
	mov	ecx,	edi
	sub	ecx,	STATIC_ZERO_memory_map

	; nagłówek utwórz za tablicą werktorów przerwań BIOSu
	mov	edi,	STATIC_ZERO_multiboot_header

	; flagi: udostępniono mapę pamięci
	mov	dword [edi + STATIC_MULTIBOOT_header.flags],	STATIC_MULTIBOOT_HEADER_FLAG_memory_map

	; rozmiar i adres mapy pamięci
	mov	dword [edi + STATIC_MULTIBOOT_header.mmap_length],	ecx
	mov	dword [edi + STATIC_MULTIBOOT_header.mmap_addr],	STATIC_ZERO_memory_map

	;-----------------------------------------------------------------------
	; przesuń kod jądra systemu do przestrzeni pamięci fizycznej pod adresem 0x00100000
	;-----------------------------------------------------------------------
	mov	esi,	STATIC_ZERO_kernel_address << STATIC_SEGMENT_to_pointer
	mov	edi,	STATIC_ZERO_kernel_address << STATIC_SEGMENT_to_pointer << STATIC_SEGMENT_to_pointer
	mov	ecx,	(file_kernel_end - file_kernel) / 0x04
	rep	movsd

;===============================================================================
; jeśli program rozruchowy jest w trybie 16 bitowym, to
;===============================================================================
%if STATIC_ZERO_bit_mode = 32
	; zwróć informacje o adresie nagłówka multiboot
	mov	ebx,	STATIC_ZERO_multiboot_header

	; wywołaj kod jądra systemu
	jmp	STATIC_ZERO_kernel_address << STATIC_SEGMENT_to_pointer << STATIC_SEGMENT_to_pointer
%endif

	;-----------------------------------------------------------------------
	; utwórz podstawową tablicę stronicowania dla trybu 64 bitowego
	;-----------------------------------------------------------------------

	; wyczyść wszystkie wiersze tabel
	xor	eax,	eax
	mov	ecx,	(STATIC_PAGE_SIZE_4KiB_byte * 0x06) / 0x04	; tablica PML4, PML3 i cztery razy PML2 (1 GiB opisanej przestrzeni na każdą tablicę PML2)
	mov	edi,	STATIC_PML4_TABLE_address
	rep	stosd

	; uzupełnij pierwszy wiersz tablicy PML4 wskazujący adres tablicy PML3 (flagi domyślne)
	mov	dword [STATIC_PML4_TABLE_address],	STATIC_PML4_TABLE_address + STATIC_PAGE_SIZE_4KiB_byte + STATIC_PAGE_FLAG_default

	; uzupełnij 4 wiersze tablicy PML3 wskazujące na adresy tablic PML2 (flagi domyślne)
	mov	dword [STATIC_PML4_TABLE_address + STATIC_PAGE_SIZE_4KiB_byte],	STATIC_PML4_TABLE_address + (STATIC_PAGE_SIZE_4KiB_byte * 0x02) + STATIC_PAGE_FLAG_default
	mov	dword [STATIC_PML4_TABLE_address + STATIC_PAGE_SIZE_4KiB_byte + 0x08],	STATIC_PML4_TABLE_address + (STATIC_PAGE_SIZE_4KiB_byte * 0x03) + STATIC_PAGE_FLAG_default
	mov	dword [STATIC_PML4_TABLE_address + STATIC_PAGE_SIZE_4KiB_byte + 0x10],	STATIC_PML4_TABLE_address + (STATIC_PAGE_SIZE_4KiB_byte * 0x04) + STATIC_PAGE_FLAG_default
	mov	dword [STATIC_PML4_TABLE_address + STATIC_PAGE_SIZE_4KiB_byte + 0x18],	STATIC_PML4_TABLE_address + (STATIC_PAGE_SIZE_4KiB_byte * 0x05) + STATIC_PAGE_FLAG_default

	; uzupełnij wszystkie wiersze tablic PML2 (flagi domyślne + każdy wpis opisuje przestrzeń fizyczną o rozmiarze 2 MiB)
	mov	eax,	STATIC_PAGE_FLAG_default + STATIC_PAGE_FLAG_2MiB_size	; flagi: rozmiar strony 2 MiB, zapisywalna, dostępna
	mov	ecx,	512 * 0x04	; 512 wierszy na jedną tablicę PML2
	mov	edi,	STATIC_PML4_TABLE_address + (STATIC_PAGE_SIZE_4KiB_byte * 0x02)

.next:
	; konfiguruj wpis
	stosd

	; przesuń wskaźnik na następny wiersz tablicy
	add	edi,	0x04	; każdy wpis ma rozmiar 8 Bajtów (tryb 64 bitowy)

	; mapuj następne 2 MiB przestrzeni pamięci fizycznej
	add	eax,	STATIC_PAGE_SIZE_2MiB_byte

	; pozostały wiersze do uzupełnienia?
	dec	ecx
	jnz	.next	; tak

	;-----------------------------------------------------------------------
	; załaduj globalną tablicę deskryptorów dla trybu 64 bitowego
	;-----------------------------------------------------------------------
	lgdt	[zero_header_gdt_64bit]

	; włącz bity NX/PAE, PGE oraz OSFXSR w rejestrze CR4
	mov	eax,	1010100000b	; NX (bit 5) - blokada wykonania kodu w stronie lub obsługa pamięci fizycznej do 64 GiB
	mov	cr4,	eax		; PGE (bit 7) - obsługa stronicowania
					; OSFXSR (bit 9) - obsługa rejestrów XMM0-15

	; załaduj do CR3 adres fizyczny tablicy PML4 jądra systemu
	mov	eax,	STATIC_PML4_TABLE_address
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
	jmp	0x0008:zero_long_mode

;===============================================================================
; 64 bitowy kod programu rozruchowego ==========================================
;===============================================================================
[BITS 64]

zero_long_mode:
	; zwróć informacje o adresie nagłówka multiboot
	mov	ebx,	STATIC_ZERO_multiboot_header

	; wywołaj kod jądra systemu
	jmp	STATIC_ZERO_kernel_address << STATIC_SEGMENT_to_pointer << STATIC_SEGMENT_to_pointer

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; format danych w postaci tablicy, wykorzystywany przez funkcję AH=0x42, przerwanie 0x13
; http://www.ctyme.com/intr/rb-0708.htm
;-------------------------------------------------------------------------------
; wszystkie tablice trzymamy pod pełnym adresem
align 0x04
zero_table_disk_address_packet:
			db	0x10		; rozmiar tablicy
			db	STATIC_EMPTY	; wartość zastrzeżona
			dw	(file_kernel_end - file_kernel) / STATIC_SECTOR_SIZE_byte	; oblicz rozmiar pliku dołączonego do sektora rozruchowego
			dw	0x0000		; przesunięcie
			dw	STATIC_ZERO_kernel_address	; segment
			dq	0x0000000000000001	; adres LBA pierwszego sektora dołączonego pliku

align 0x04	; wszystkie tablice trzymamy pod pełnym adresem
zero_table_gdt_32bit:
	; deskryptor zerowy
	dq	STATIC_EMPTY
	; deskryptor kodu
	dq	0000000011001111100110000000000000000000000000001111111111111111b
	; deskryptor danych
	dq	0000000011001111100100100000000000000000000000001111111111111111b
zero_table_gdt_32bit_end:

zero_header_gdt_32bit:
	dw	zero_table_gdt_32bit_end - zero_table_gdt_32bit - 0x01
	dd	zero_table_gdt_32bit

align 0x08	; wszystkie tablice trzymamy pod pełnym adresem
zero_table_gdt_64bit:
	; deskryptor zerowy
	dq	STATIC_EMPTY
	; deskryptor kodu
	dq	0000000000100000100110000000000000000000000000000000000000000000b
	; deskryptor danych
	dq	0000000000100000100100100000000000000000000000000000000000000000b
zero_table_gdt_64bit_end:

zero_header_gdt_64bit:
	dw	zero_table_gdt_64bit_end - zero_table_gdt_64bit - 0x01
	dd	zero_table_gdt_64bit

;-------------------------------------------------------------------------------
; znacznik sektora rozruchowego
times	510 - ($ - $$)	db	STATIC_EMPTY
			dw	STATIC_ZERO_magic	; czysta magija ;>

;-------------------------------------------------------------------------------
file_kernel:
	;-----------------------------------------------------------------------
	; dołącz plik jądra systemu
	;-----------------------------------------------------------------------
	incbin	"build/kernel"
	align	STATIC_SECTOR_SIZE_byte	; wyrównaj kod do pełnego sektora o rozmiarze 512 Bajtów
file_kernel_end:
