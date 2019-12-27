;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; wszystkie procedury inicjalizacyjne zostały zaprojektowane z myślą
	; o trybie 64 bitowym procesora, do tej pory Cyjon nie był kompatybilny
	; z programem rozruchowym GRUB, zatem aby tą kompatybilność uzyskać
	; najniższym kosztem, przełączam od razu procesor w tryb 64 bitowy
	;
	; program rozruchowy "Zero" zwraca już taki sam nagłówek Multiboot
	; oraz przekazuje procesor w trybie 32 bitowym do jądra systemu
	;
	; kod który przełącza procesor w tryb 64 bitowy, został zapożyczony
	; z programu rozruchowego "Zero" (bez modyfikacji)
	;-----------------------------------------------------------------------

	;-----------------------------------------------------------------------
	; przełącz procesor w tryb 64 bitowy
	;-----------------------------------------------------------------------
	%include	"kernel/init/long_mode.asm"

	;-----------------------------------------------------------------------
	; domyślny komunikat błędu
	;-----------------------------------------------------------------------
	%include	"kernel/init/panic.asm"

	;-----------------------------------------------------------------------
	; zmienne - wykorzystywane podczas inicjalizacji środowiska jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init/data.asm"
	;-----------------------------------------------------------------------

	;-----------------------------------------------------------------------
	; multiboot - nagłówek dla programu rozruchowego GRUB
	;-----------------------------------------------------------------------
	%include	"kernel/init/multiboot.asm"

;===============================================================================
; 64 bitowy kod jądra systemu ==================================================
;===============================================================================
[BITS 64]

	;-----------------------------------------------------------------------
	; procdura inicjalizująca kontroler APIC
	;-----------------------------------------------------------------------
	%include	"kernel/init/apic.asm"

kernel_init_long_mode:
	;-----------------------------------------------------------------------
	; inicjalizacja przestrzeni trybu tekstowego
	;-----------------------------------------------------------------------
	%include	"kernel/init/video.asm"

	;-----------------------------------------------------------------------
	; utworzenie binarnej mapy pamięci i oznaczenie w niej jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init/memory.asm"

	;-----------------------------------------------------------------------
	; przetworzenie tablic ACPI
	;-----------------------------------------------------------------------
	%include	"kernel/init/acpi.asm"

	;-----------------------------------------------------------------------
	; utwórz stronicowanie docelowe jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init/page.asm"

	;-----------------------------------------------------------------------
	; utwórz Globalną Tablicę Deskryptorów
	;-----------------------------------------------------------------------
	%include	"kernel/init/gdt.asm"

	;-----------------------------------------------------------------------
	; utwórz Tablicę Deskryptorów Przerwań
	;-----------------------------------------------------------------------
	%include	"kernel/init/idt.asm"

	;-----------------------------------------------------------------------
	; konfiguruj zegar czasu rzeczywistego - uptime systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init/rtc.asm"

	;-----------------------------------------------------------------------
	; skonfiguruj obsługę urządzeń wskazujących
	;-----------------------------------------------------------------------
	%include	"kernel/init/ps2.asm"

	;-----------------------------------------------------------------------
	; inicjalizuj jeden z dostępnych interfejsów sieciowych
	;-----------------------------------------------------------------------
	%include	"kernel/init/network.asm"

	;-----------------------------------------------------------------------
	; utwórz kolejkę zadań
	;-----------------------------------------------------------------------
	%include	"kernel/init/task.asm"

	;-----------------------------------------------------------------------
	; przygotuj komunikację międzyprocesową
	;-----------------------------------------------------------------------
	%include	"kernel/init/ipc.asm"

	;-----------------------------------------------------------------------
	; dodaj do kolejki zadań zestaw usług zarządzających środowiskiem jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init/services.asm"

	;-----------------------------------------------------------------------
	; konfiguruj wew. przerwanie lokalnego kontrolera APIC (przełączanie zadań w kolejce)
	;-----------------------------------------------------------------------
	call	kernel_init_apic

	; ustaw domyślny czas pomiędzy wywołaniami przerwania (jednostki)
	mov	dword [rsi + KERNEL_APIC_TICR_register],	DRIVER_RTC_Hz

	; poinformuj APIC o obsłużeniu aktualnego przerwania sprzętowego lokalnego
	mov	dword [rsi + KERNEL_APIC_EOI_register],	STATIC_EMPTY

	; za chwilę wywołana zostanie procedura kolejki zadań!

kernel_init_clean:
	;-----------------------------------------------------------------------
	; usuń wszystkie procedury inicjalizacyjne - odzyskujemy miejsce
	;-----------------------------------------------------------------------

	; rozmiar przestrzeni inicjalizacyjnej
	mov	ecx,	kernel_init_clean - $$
	call	library_page_from_size	; w stronach

	; zwolnij
	mov	rdi,	KERNEL_BASE_address
	call	kernel_memory_release

	; skocz do głównej pętli jądra systemu
	jmp	kernel
