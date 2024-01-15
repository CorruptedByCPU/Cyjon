;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

; Use:
; nasm - http://www.nasm.us/

; zestaw imiennych wartości stałych
%include	"config.asm"

;-------------------------------------------------------------------------------
; 32 bitowy kod jądra systemu
;-------------------------------------------------------------------------------
[BITS 32]

; położenie kodu jądra systemu w pamięci fizycznej/logicznej
[ORG VARIABLE_KERNEL_PHYSICAL_ADDRESS]

; NAGŁÓWEK =====================================================================
header:
	; informacja dla programu rozruchowego Omega
	db	VARIABLE_KERNEL_MODE_32BIT	; kod jądra systemu rozpoczyna się od 32 bitowych instrukcji
; NAGŁÓWEK KONIEC ==============================================================

_start:
	; poinformuj jądro systemu o wykorzystaniu własnego programu rozruchowego
	mov	byte [variable_bootloader_own],	VARIABLE_TRUE

	; skocz do procedury przełączania procesora w tryb 64 bitowy
	jmp	entry	; plik engine/init.asm

variable_bootloader_own	db	VARIABLE_EMPTY

; multiboot zostanie wyłączony na czas konstruowania trybu graficznego
%include	"engine/multiboot.asm"
%include	"engine/init.asm"

%include	"bootloader/stage2/paging.asm"

; rozpocznij 64 bitowy kod jądra systemu od pełnego adresu
align	0x0100

;-------------------------------------------------------------------------------
; 64 bitowy kod jądra systemu
;-------------------------------------------------------------------------------
[BITS 64]

kernel:
	; ustaw deskryptory danych, ekstra i stosu
	mov	ax,	VARIABLE_KERNEL_DS_SELECTOR

	; podstawowe segmenty
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra
	mov	ss,	ax	; segment stosu

	; przygotuj podstatowe informacje o przestrzeni pamięci ekranu
	call	cyjon_screen_init

	; zachowaj adres mapy pamięci
	push	rbx	; GRUB
	push	rsi	; OMEGA

	; wyświetl informacje powitalną
	mov	rbx,	VARIABLE_COLOR_LIGHT_GREEN
	mov	cl,	VARIABLE_FULL
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_kernel_welcome
	call	cyjon_screen_print_string

	; przywróć adres mapy pamięci
	pop	rsi	; OMEGA
	pop	rbx	; GRUB

	; zarejestruj dostępną przestrzeń pamięci w Binarnej Mapie Pamięci
	call	binary_memory_map

	; utwórz własną Globalną Tablicę Deskryptorów
	call	global_descriptor_table

	; utwórz nowe tablice stronicowania dla jądra systemu
	call	recreate_paging

	; przygotuj obsługę wyjątków i przerwań procesora, przerwań użyktownika
	call	interrupt_descriptor_table

	; przemapuj numery przerwań sprzętowych pod 0x20..0x2F
	call	programmable_interrupt_controller

	; ustaw częstotliwość wywołań przerwania sprzętowego IRQ0
	call	programmable_interval_timer

	; przygotuj kolejkę procesów (nazwaną 'Serpentyna') i załaduj do niej jądro systemu
	call	multitasking

	; załaduj podstawową macierz znaków klawiatury
	call	keyboard

	; pobierz czas z CMOSu
	call	cmos

	; wykryj dostępne nośniki ATA (tylko dyski twarde)
	call	ide_initialize

	; włączamy przerwania i wyjątki procesora
	sti	; tchnij życie

	; przygotuj wirtualny system plików na programy wbudowane
	call	vfs

	; inicjalizuj pierwszą dostępną kartę sieciową
	call	network_init

	; zarejestruj dołączone oprogramowanie w wirtualnym systemie plików jądra systemu
	call	move_included_files_to_virtual_filesystem

	; uruchom demony systemu :]
	call	daemons

	; uruchom pierwszy proces "init"
	mov	rcx,	qword [files_table]	; ilość znaków w nazwie pliku
	mov	rsi,	files_table + ( VARIABLE_QWORD_SIZE * 0x05 )	; wskaźnik do nazwy pliku
	xor	rdx,	rdx	; brak argumentów
	xor	rdi,	rdi	; ^
	call	cyjon_process_init

%include	"engine/elive.asm"
%include	"engine/screen.asm"
%include	"engine/binary_memory_map.asm"
%include	"engine/paging.asm"
%include	"engine/global_descriptor_table.asm"
%include	"engine/interrupt_descriptor_table.asm"
%include	"engine/multitasking.asm"
%include	"engine/programmable_interrupt_controller.asm"
%include	"engine/programmable_interval_timer.asm"
%include	"engine/vfs.asm"
%include	"engine/keyboard.asm"
%include	"engine/mouse.asm"
%include	"engine/services.asm"
%include	"engine/process.asm"
%include	"engine/network.asm"
%include	"engine/cmos.asm"

%include	"engine/variables.asm"

%include	"engine/daemon/daemon_garbage_collector.asm"
%include	"engine/daemon/daemon_ethernet.asm"
%include	"engine/daemon/daemon_tcp_ip_stack.asm"
%include	"engine/daemon/daemon_network_loopback.asm"
%include	"engine/daemon/daemon_ide_io.asm"

%include	"engine/drivers/pci.asm"
%include	"engine/drivers/ide.asm"
%include	"engine/drivers/network/i8254x.asm"

; wczytaj lokalizacje jądra systemu
%push
	%defstr		%$kernel_locale			VARIABLE_KERNEL_LOCALE
	%strcat		%$include_kernel_locale,	"locale/", %$kernel_locale, ".asm"
	%include	%$include_kernel_locale
%pop

%include	"library/align_address_up_to_page.asm"
%include	"library/find_free_bit.asm"
%include	"library/compare_string.asm"
%include	"library/trim.asm"
%include	"library/translate_size_and_type.asm"
%include	"library/bcd.asm"

%include	"font/terminus-8x16n-compressed.asm"

; wskaźnik końca kodu jądra wyrównaj do pełnego adresu strony
align	0x1000

; wszystkie dołączone programy zostaną zarejestrowane w wirtualnym systemie plików jądra systemu
; a poniższa przestrzeń zwolniona
%include	"engine/daemons.asm"
%include	"engine/software.asm"

; koniec kodu jądra systemu
kernel_end:
