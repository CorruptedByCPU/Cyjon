;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	; procesor logiczny?
	cmp	byte [kernel_init_smp_semaphore],	STATIC_FALSE
	je	kernel_init	; nie

	; ;-----------------------------------------------------------------------
	; ; AP - inicjalizacja procesora logicznego
	; ;-----------------------------------------------------------------------
	%include	"kernel/init/ap.asm"

	;-----------------------------------------------------------------------
	; zmienne - wykorzystywane podczas inicjalizacji środowiska jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init/data.asm"
	;-----------------------------------------------------------------------

	;-----------------------------------------------------------------------
	; procdura inicjalizująca kontroler APIC
	;-----------------------------------------------------------------------
	%include	"kernel/init/apic.asm"

kernel_init:
	;-----------------------------------------------------------------------
	; inicjalizuj port COM1 (stdlog)
	;-----------------------------------------------------------------------
	%include	"kernel/init/serial.asm"

	;-----------------------------------------------------------------------
	; inicjalizacja przestrzeni trybu tekstowego
	;-----------------------------------------------------------------------
	%include	"kernel/init/video.asm"

	;-----------------------------------------------------------------------
	; utworzenie binarnej mapy pamięci i oznaczenie w niej jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init/memory.asm"

	;-----------------------------------------------------------------------
	; utwórz tablicę potoków
	;-----------------------------------------------------------------------
	%include	"kernel/init/stream.asm"

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
	; utwórz wirtualny system plików
	;-----------------------------------------------------------------------
	%include	"kernel/init/vfs.asm"

	;-----------------------------------------------------------------------
	; inicjuj dostępne nośniki danych
	;-----------------------------------------------------------------------
	%include	"kernel/init/storage.asm"

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

	; za chwilę wywołana zostanie procedura kolejki zadań!

	;-----------------------------------------------------------------------
	; SMP - uruchom pozostałe procesory logiczne
	;-----------------------------------------------------------------------
	%include	"kernel/init/smp.asm"

.wait:
	; pobierz ilość działających procesorów logicznych
	mov	al,	byte [kernel_init_ap_count]
	inc	al	; procesor BSP nie jest liczony jako logiczny

	; wszystkie procesory logiczne zostały zainicjowane?
	cmp	al,	byte [kernel_apic_count]
	jne	.wait	; nie, czekaj

	;-----------------------------------------------------------------------
	; INICJALIZACJA ZAKOŃCZONA
	;-----------------------------------------------------------------------

	; poinformuj o zakończeniu inicjalizacji
	mov	byte [kernel_init_semaphore],	STATIC_FALSE

; wyrównaj pozycję kodu do pełnej strony
align	STATIC_PAGE_SIZE_byte,	db	STATIC_NOTHING

.clean:
	; zwolnij przestrzeń zajętą przez procedury inicjalizacyjne
	mov	ecx,	.clean - $$
	mov	rdi,	KERNEL_BASE_address
	call	library_page_from_size	; zamień rozmiar przestrzeni na strony
	call	kernel_memory_release
