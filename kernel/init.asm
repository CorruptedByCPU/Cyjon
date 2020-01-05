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

	; procesor logiczny?
	cmp	byte [kernel_init_smp_semaphore],	STATIC_FALSE
	je	.entry	; nie

	;-----------------------------------------------------------------------
	; AP - inicjalizacja procesora logicznego
	;-----------------------------------------------------------------------
	%include	"kernel/init/ap.asm"

.entry:
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

kernel_init:
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
	; przygotuj komunikację międzyprocesową
	;-----------------------------------------------------------------------
	%include	"kernel/init/ipc.asm"

	;-----------------------------------------------------------------------
	; inicjalizuj jeden z dostępnych interfejsów sieciowych
	;-----------------------------------------------------------------------
	%include	"kernel/init/network.asm"

	;-----------------------------------------------------------------------
	; utwórz kolejkę zadań
	;-----------------------------------------------------------------------
	%include	"kernel/init/task.asm"

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

	; włącz obsługę przerwań
	sti

	; za chwilę wywołana zostanie procedura kolejki zadań!

	;-----------------------------------------------------------------------
	; SMP - uruchom pozostałe procesory logiczne
	;-----------------------------------------------------------------------
	%include	"kernel/init/smp.asm"

.wait:
	; wszystkie procesory logiczne zostały zainicjowane?
	mov	al,	byte [kernel_init_ap_count]
	inc	al	; procesor BSP nie jest liczony jako logiczny
	cmp	al,	byte [kernel_apic_count]
	jne	.wait	; nie, czekaj

	; usuń środowisko inicjalizacyjne
	jmp	clean
