;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

ACPI_MADT_ENTRY_lapic			equ	0x00
ACPI_MADT_ENTRY_ioapic			equ	0x01
ACPI_MADT_ENTRY_iso			equ	0x02
ACPI_MADT_ENTRY_x2apic			equ	0x09

ACPI_MADT_APIC_FLAG_ENABLED_bit		equ	0

struc	ACPI_STRUCTURE_RSDP
	.signature			resb	8
	.checksum			resb	1
	.oem_id				resb	6
	.revision			resb	1
	.rsdt_address			resb	4
	.SIZE:
endstruc

struc	ACPI_STRUCTURE_RSDT
	.signature			resb	4
	.length				resb	4
	.revision			resb	1
	.checksum			resb	1
	.oem_id				resb	6
	.oem_table_id			resb	8
	.oem_revision			resb	4
	.creator_id			resb	4
	.creator_revision		resb	4
	.SIZE:
endstruc

struc	ACPI_STRUCTURE_MADT
	.signature			resb	4
	.length				resb	4
	.revision			resb	1
	.checksum			resb	1
	.oem_id				resb	6
	.oem_table_id			resb	8
	.oem_revision			resb	4
	.creator_id			resb	4
	.creator_revision		resb	4
	.apic_address			resb	4
	.flags				resb	4
	.SIZE:
endstruc

struc	ACPI_STRUCTURE_MADT_entry
	.type				resb	1
	.length				resb	1
endstruc



struc	ACPI_STRUCTURE_MADT_APIC
	.type				resb	1
	.length				resb	1
	.cpu_id				resb	1
	.apic_id			resb	1
	.flags				resb	4
	.SIZE:
endstruc

struc	ACPI_STRUCTURE_MADT_IOAPIC
	.type				resb	1
	.length				resb	1
	.ioapic_id			resb	1
	.reserved			resb	1
	.base_address			resb	4
	.gsib				resb	4	; Global System Interrupt Base
	.SIZE:
endstruc

struc	ACPI_STRUCTURE_MADT_ISO	; Interrupt Source Override
	.type				resb	1
	.length				resb	1
	.bus_source			resb	1
	.irq_source			resb	1
	.gsi				resb	4	; Global System Interrupt
	.flags				resb	2
	.SIZE:
endstruc

struc	ACPI_STRUCTURE_MADT_NMI	; Non-maskable Interrupts
	.type				resb	1
	.length				resb	1
	.acpi_id			resb	1
	.flags				resb	2
	.lint				resb	1
	.SIZE:
endstruc

;===============================================================================
kernel_init_acpi:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8

	; odszukaj nagłówek Root System Description Pointer w tabelach ACPI
	mov	rbx,	"RSD PTR "

	; pobierz wskaźnik segmentu EBDA
	movzx	esi,	word [0x040E]
	; zamień wskaźnik segmentu na adres bezwzględny
	shl	esi,	STATIC_MULTIPLE_BY_16_shift

.rsdp_search:
	; pobierz 8 Bajtów
	lodsq

	; znaleziono nagłówek RSDP?
	cmp	rax,	rbx
	je	.rsdp_found	; tak

	; koniec przeszukiwanej przestrzeni?
	cmp	esi,	0x000FFFFF
	jb	.rsdp_search	; nie

	; nie znaleziono nagłówka RSDP
	mov	ecx,	kernel_init_string_error_acpi_end - kernel_init_string_error_acpi
	mov	rsi,	kernel_init_string_error_acpi

.error:
	; wyświetl komunikat
	jmp	kernel_panic

.rsdp_found:
	; zachowaj wskaźnik do nagłówka RSDP
	push	rsi

	;-----------------------------------------------------------------------
	; sumuj wszystkie Bajty nagłówka RSDP
	xor	al,	al
	mov	ecx,	ACPI_STRUCTURE_RSDP.SIZE

	; cofnij wskaźnik na początek nagłówka
	sub	rsi,	ACPI_STRUCTURE_RSDP.checksum

.checksum:
	; utwórz sumę kontrolną
	add	al,	byte [rsi]

	; przesuń wskaźnik na następną wartość
	inc	rsi

	; kontynuuj z pozostałymi wartościami
	loop	.checksum
	;=======================================================================

	; przywróć wskaźnik do nagłówka RSDP
	pop	rsi

	; suma kontrolna wynosi ZERO?
	test	al,	al
	jnz	.rsdp_search	; nie, to nie jest poprawny nagłówek RSDP, szukaj dalej

.rsdp:
	; ustaw wskaźnik na początek nagłówka
	sub	rsi,	ACPI_STRUCTURE_RSDP.checksum

	; sprawdź wersje tablicy ACPI w którym znajduje się nagłówek RSDP
	cmp	byte [rsi + ACPI_STRUCTURE_RSDP.revision],	0x00
	jne	.extended	; ACPI v2.0+

	; pobierz adres tablicy RSDT na podstawie wskaźnika w nagłówku
	mov	edi,	dword [rsi + ACPI_STRUCTURE_RSDP.rsdt_address]

	; ustaw komunikat błędu: uszkodzona tablica ACPI
	mov	ecx,	kernel_init_string_error_acpi_corrupted_end - kernel_init_string_error_acpi_corrupted
	mov	rsi,	kernel_init_string_error_acpi_corrupted

	; sprawdź sygnaturę tablicy RSDT
	cmp	dword [rdi + ACPI_STRUCTURE_RSDT.signature],	"RSDT"
	jne	.error	; błąd

	;=======================================================================

	; pobierz ilość wpisów w tablicy RSDT (koryguj o rozmiar nagłówka)
	mov	ecx,	dword [rdi + ACPI_STRUCTURE_RSDT.length]
	sub	ecx,	ACPI_STRUCTURE_RSDT.SIZE
	shr	ecx,	STATIC_DIVIDE_BY_DWORD_shift

	; przesuń wskaźnik na wpisy tablicy RSDT
	add	rdi,	ACPI_STRUCTURE_RSDT.SIZE

.rsdt:
	; pobierz adres nagłówka z wpisu
	mov	esi,	dword [rdi]

	; nagłówek tablicy MADT (Multiple APIC Description Table)?
	cmp	dword [rsi + ACPI_STRUCTURE_MADT.signature],	"APIC"
	je	.madt	; tak, przetwórz

.rsdt_continue:
	; przesuń wskaźnik na następny wpis w tablicy RSDT
	add	rdi,	STATIC_DWORD_SIZE_byte

	; koniec wpisów w tablicy RSDT?
	dec	ecx
	jnz	.rsdt	; nie, kontynuuj z pozostałymi

	; ustaw komunikat błędu: nie znaleziono tablicy APIC
	mov	ecx,	kernel_init_string_error_apic_end - kernel_init_string_error_apic
	mov	rsi,	kernel_init_string_error_apic

	; przetworzono choć jedną tablicę APIC?
	cmp	byte [kernel_apic_count],	STATIC_EMPTY
	je	.error	; nie, wyświetl komunikat błędu

	; ustaw komunikat błędu: nie znaleziono tablicy I/O APIC
	mov	ecx,	kernel_init_string_error_ioapic_end - kernel_init_string_error_ioapic
	mov	rsi,	kernel_init_string_error_ioapic

	; przetworzono choć jedną tablicę I/O APIC?
	cmp	byte [kernel_init_ioapic_semaphore],	STATIC_FALSE
	je	.error	; nie, wyświetl komunikat błędu

	; kontynuuj inicjalizacje środowiska jądra systemu
	jmp	.end

	;=======================================================================

.madt:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; zachowaj adres tablicy APIC
	mov	eax,	dword [rsi + ACPI_STRUCTURE_MADT.apic_address]
	mov	dword [kernel_apic_base_address],	eax

	; zachowaj rozmiar tablicy APIC
	mov	ecx,	dword [rsi + ACPI_STRUCTURE_MADT.length]
	mov	dword [kernel_apic_size],	ecx

	; przeszukaj tablicę MADT za dostępnymi procesorami logicznymi (tzw. LAPIC)
	sub	ecx,	ACPI_STRUCTURE_MADT.SIZE	; koryguj rozmiar tablicy MADT o nagłówek
	add	rsi,	ACPI_STRUCTURE_MADT.SIZE	; przesuń wskaźnik na pierwszy wpis tablicy MADT

	; informacje o dostępnych procesorach logicznych przechowaj w tablicy
	mov	rdi,	kernel_apic_id_table

.madt_loop:
	; znaleziono procesor logiczny?
	cmp	byte [rsi + ACPI_STRUCTURE_MADT_entry.type],	ACPI_MADT_ENTRY_lapic
	je	.madt_apic	; tak, przetwórz

	; znaleziono I/O APIC?
	cmp	byte [rsi + ACPI_STRUCTURE_MADT_entry.type],	ACPI_MADT_ENTRY_ioapic
	je	.madt_ioapic	; tak, przetwórz

	; nie rozpoznano lub brak obsługi

.madt_next_entry:
	; przesuń wskaźnik na następny wpis w tablicy MADT
	movzx	eax,	byte [rsi + ACPI_STRUCTURE_MADT_entry.length]
	add	rsi,	rax

	; koniec wpisów?
	sub	rcx,	rax
	jnz	.madt_loop	; nie, kontynuuj

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; kontynuuj przetwarzanie tablicy RSDT
	jmp	.rsdt_continue

.madt_apic:
	; procesor logiczny aktywny?
	bt	word [rsi + ACPI_STRUCTURE_MADT_APIC.flags],	ACPI_MADT_APIC_FLAG_ENABLED_bit
	jnc	.madt_next_entry	; nie, pomiń rejestrację

	; procesor logiczny, dostępny
	inc	word [kernel_apic_count]

	; pobierz i zachowaj identyfikator procesora logicznego
	mov	al,	byte [rsi + ACPI_STRUCTURE_MADT_APIC.cpu_id]
	stosb

	; identyfikator procesora logicznego jest wyższy?
	cmp	al,	byte [kernel_init_apic_id_highest]
	jbe	.madt_next_entry	; nie

	; zapamiętaj
	mov	byte [kernel_init_apic_id_highest],	al

	; kontynuuj
	jmp	.madt_next_entry

.madt_ioapic:
	; przetworzono już IO APIC?
	cmp	byte [kernel_init_ioapic_semaphore],	STATIC_TRUE
	je	.madt_next_entry	; tak, nie obsługujemy pozostałych kontrolerów I/O APIC

	; pobierz identyfikator pierwszego przerwania obsługiwanego przez ten kontroler
	mov	eax,	dword [rsi + ACPI_STRUCTURE_MADT_IOAPIC.gsib]

	; kontroler obsługuje wektory przerwań 0+?
	test	al,	al
	jnz	.madt_next_entry	; nie, pomiń ten kontroler

	; zachowaj adres kontrolera I/O APIC
	mov	eax,	dword [rsi + ACPI_STRUCTURE_MADT_IOAPIC.base_address]
	mov	dword [kernel_io_apic_base_address],	eax

	; przetworzono wpis o kontrolerze I/O APIC
	mov	byte [kernel_init_ioapic_semaphore],	STATIC_TRUE

	; kontynuuj
	jmp	.madt_next_entry

.extended:
	; ustaw komunikat błędu: nieobsługiwana wersja tablicy ACPI
	mov	ecx,	kernel_init_string_error_acpi_2_end - kernel_init_string_error_acpi_2
	mov	rsi,	kernel_init_string_error_acpi_2

	; wyświetl komunikat
	jmp	kernel_panic

.end:
