;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_SCREEN_TEXT_MODE_ADDRESS	equ	0x000B8000
VARIABLE_MEMORY_MAP_ADDRESS		equ	0x00000500

%include	"config.asm"

; 16 Bitowy kod programu
[BITS 16]

; położenie kodu programu w pamięci fizycznej 0x0000:0x1000
[ORG 0x1000]

;-------------------------------------------------------------------------------
; Program rozruchowy wspiera jądra systemu 32 i 64 bitowe.                     -
;-------------------------------------------------------------------------------

start:
	; wyczyść DirectionFlag
	cld

	; wyłącz przerwania sprzętowe
	call	stage2_disable_pic

	; inicjalizuj tryb tekstowy 80x25
	mov	ax,	0x0003
	int	0x10

	; załaduj naszą mapę czcionki
	call	stage2_reload_font

	; sprawdź typ procesora
	call	stage2_check_cpu

	; odblokuj linię A20 (dostęp do pamięci powyżej adresu 0x00100000)
	call	stage2_unlock_a20

	; przygotuj mapę pamięci
	call	stage2_memory_map

	; przełącz w tryb graficzny
	call	stage2_change_graphics_mode

;-------------------------------------------------------------------------------
; Przełączenie programu rozruchowego w tryb 32 bitowy.
;-------------------------------------------------------------------------------

	; wyłącz obsługę wyjątków i przerwań
	cli

	; załaduj globalną tablicę deskryptorów
	lgdt	[gdt_structure_32bit]

	; przełącz procesor w tryb 32 bitowy
	mov	eax,	cr0
	bts	eax,	0	; włącz pierwszy bit rejestru cr0
	mov	cr0,	eax	; aktualizuj

	; skocz do 32 bitowego kodu
	jmp	long 0x0008:stage2_protected_mode

; procedury 16 bitowe
%include	"bootloader/stage2/disable_pic.asm"
%include	"bootloader/stage2/check_cpu.asm"
%include	"bootloader/stage2/unlock_a20.asm"
%include	"bootloader/stage2/memory_map.asm"
%include	"bootloader/stage2/print_16bit.asm"
%include	"bootloader/stage2/gdt_structure.asm"
%include	"bootloader/stage2/reload_font.asm"
%include	"bootloader/stage2/change_graphics_mode.asm"
%include	"font/terminus-8x16n-compressed.asm"

; rozpocznij kod 32 Bitowy od pełnego adresu
align	0x04

;-------------------------------------------------------------------------------
; 32 bitowy kod programu rozruchowego
;-------------------------------------------------------------------------------
[BITS 32]

stage2_protected_mode:
	; ustaw deskryptory danych, ekstra i stosu
	mov	ax,	0x0010

	; podstawowe segmenty
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra
	mov	ss,	ax	; segment stosu

	; ustaw wskaźnik szczytu stosu na koniec pierwszych 64 KiB pamięci
	mov	esp,	0x00010000

;-------------------------------------------------------------------------------
; Inicjalizacja sterownika kontrolera dysku twardego
;-------------------------------------------------------------------------------

	; przygotuj jeden ze sterowników do dysku twardego
	; jeśli zostanie wykryty pierwszy, drugi zignoruj

	; sprawdź dostępność nośnika SATA
	jmp	stage2_sata_drive_initialize

.drive_select_ide:
	; sprawdź dostępność nośnika PATA
	call	stage2_ide_drive_initialize

;-------------------------------------------------------------------------------
; Wczytanie kodu jądra systemu do pamięci
;-------------------------------------------------------------------------------
.drive_selected:
	; oblicz rozmiar jądra systemu w sektorach
	mov	ecx,	end_of_kernel
	sub	ecx,	kernel
	shr	ecx,	9	; / 512 Bajtów na sektor
	inc	ecx		; +1 sektor, reszta z dzielenia (nawet jak jej nie było)

	; oblicz pozycje jądra systemu na nośniku w sektorach
	mov	eax,	kernel
	sub	eax,	start
	shr	eax,	9	; / 512 Bajtów
	inc	eax		; +1 bootsector

	; załaduj jądro systemu operacyjnego do pamięci pod adres 0x00100000
	mov	edi,	VARIABLE_KERNEL_PHYSICAL_ADDRESS
	call	dword [variable_disk_interface_read]

;-------------------------------------------------------------------------------
; Analiza nagłówa jądra systemu (32 czy 64 bitowe?)
;-------------------------------------------------------------------------------
	; sprawdź nagłówek jądra systemu
	cmp	byte [VARIABLE_KERNEL_PHYSICAL_ADDRESS],	0x40
	je	.change_to_long_mode_64bit

;-------------------------------------------------------------------------------
; Uruchomienie jądra systemu 32 bitowego
;-------------------------------------------------------------------------------
	; wyczyść zbędne rejestry
	xor	eax,	eax
	xor	ebx,	ebx
	xor	ecx,	ecx
	xor	edx,	edx
	xor	edi,	edi

	; zwróć informacje gdzie znajduje się mapa pamięci
	mov	esi,	VARIABLE_MEMORY_MAP_ADDRESS

	; tryb graficzny włączony?
	cmp	byte [variable_video_mode_semaphore],	VARIABLE_FALSE
	je	.no_graphics

	; zwróć informacje gdzie znajduje się mapa informacji o trybie graficznym
	mov	edi,	variable_mode_info_block

.no_graphics:
	; skocz do kodu jądra systemu operacyjnego
	jmp	long 0x08:VARIABLE_KERNEL_PHYSICAL_ADDRESS + 1	; +1 nagłówek

;-------------------------------------------------------------------------------
; Przełączenie programu rozruchowego w tryb 64 bitowy.
;-------------------------------------------------------------------------------
.change_to_long_mode_64bit:
	; utwórz podstawowe stronicowanie
	call	stage2_paging

	; załaduj globalną tablicę deskryptorów
	lgdt	[gdt_structure_64bit]

	; włącz PGE, PAE i PSE w CR4
	mov	eax,	cr4
	or	eax,	0x0000000B0		; PGE (bit 7), PAE (bit 5) i PSE (bit 4)
	mov	cr4,	eax

	; załaduj do CR3 adres PML4
	mov	eax,	VARIABLE_MEMORY_PAGING_ADDRESS
	mov	cr3,	eax

	; włącz w rjestrze EFER MSR tryb długi oraz SYSCALL/SYSRET
	mov	ecx,	0xC0000080	; numer EFER MSR
	rdmsr	; odczytaj
	or	eax,	00000000000000000000000100000001b	; ustawiamy bit 7 (LME) i bit 0
	wrmsr	; zapisz

	; włącz stronicowanie i zarazem tryb kompatybilności (64 bit)
	mov	eax,	cr0
	or	eax,	0x80000000	; włącz 31 bit (PG)
	mov	cr0,	eax

	; skocz do 64 bitowego kodu
	jmp	0x0008:stage2_long_mode

; rozpocznij kod 64 Bitowy od pełnego adresu
align	0x04

;-------------------------------------------------------------------------------
; 64 bitowy kod programu rozruchowego
;-------------------------------------------------------------------------------
[BITS 64]

stage2_long_mode:
;-------------------------------------------------------------------------------
; Uruchomienie jądra systemu 32 bitowego
;-------------------------------------------------------------------------------
	; wyczyść zbędne informacje
	xor	rax,	rax
	xor	rbx,	rbx
	xor	rcx,	rcx
	xor	rdx,	rdx
	xor	rdi,	rdi

	; zwróć informacje gdzie znajduje się mapa pamięci
	mov	rsi,	VARIABLE_MEMORY_MAP_ADDRESS

	; tryb graficzny włączony?
	cmp	byte [variable_video_mode_semaphore],	VARIABLE_FALSE
	je	.no_graphics

	; zwróć informacje gdzie znajduje się mapa informacji o trybie graficznym
	mov	edi,	variable_mode_info_block

.no_graphics:

	; skocz do kodu jądra systemu operacyjnego
	jmp	VARIABLE_KERNEL_PHYSICAL_ADDRESS + 0x01	; +1 nagłówek

; zmienna określa adres procedury odczytującej dane z nośnika,
; jest ona uzupełniana na podstawie rozpoznania sterowników
variable_disk_interface_read	dd	VARIABLE_EMPTY

; procedury 32 bitowe
%include	"bootloader/stage2/print_32bit.asm"
%include	"bootloader/stage2/sata_driver_32bit.asm"
%include	"bootloader/stage2/ide_driver_32bit.asm"
%include	"bootloader/stage2/pci_driver_32bit.asm"
%include	"bootloader/stage2/paging.asm"

; wyrównaj położenie kodu jądra systemu do pełnego sektora
align	0x200

kernel:
	incbin	"build/kernel.bin"
end_of_kernel:
