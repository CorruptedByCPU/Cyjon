;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
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

struc	ACPI_STRUCTURE_XSDP
	.rsdp				resb	ACPI_STRUCTURE_RSDP.SIZE
	.length				resb	4
	.xsdt_address			resb	8
	.checksum			resb	1
	.reserved			resb	3
	.SIZE:
endstruc

struc	ACPI_STRUCTURE_RSDT_or_XSDT
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
	; odszukaj nagłówek Root/Extended System Description Pointer
	mov	rbx,	"RSD PTR "

	; pobierz wskaźnik segmentu EBDA
	movzx	esi,	word [0x040E]

	; zamień wskaźnik segmentu na adres bezwzględny
	shl	esi,	STATIC_MULTIPLE_BY_16_shift

	;  domyślnie spodziewamy się ACPI w wersji 1.0
	mov	r8b,	STATIC_TRUE

.rsdp_search:
	; pobierz 8 Bajtów
	lodsq

	; znaleziono nagłówek RSDP/XSDP?
	cmp	rax,	rbx
	je	.rsdp_found	; tak

	; koniec przeszukiwanej przestrzeni?
	cmp	esi,	0x000FFFFF
	jb	.rsdp_search	; nie

	; komunikat błędu
	mov	rsi,	kernel_init_string_error_acpi_header

.error:
	; wyświetl komunikat
	jmp	kernel_panic

.rsdp_found:
	; zachowaj wskaźnik do nagłówka RSDP lub XSDP
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

.rsdp_or_xsdp:
	; ustaw wskaźnik na początek nagłówka
	sub	rsi,	ACPI_STRUCTURE_RSDP.checksum

	; sprawdź wersje tablicy ACPI w którym znajduje się nagłówek RSDP
	cmp	byte [rsi + ACPI_STRUCTURE_RSDP.revision],	0x00
	jne	.extended	; wersja 1.0

	; pobierz adres tablicy RSDT na podstawie wskaźnika w nagłówku
	mov	edi,	dword [rsi + ACPI_STRUCTURE_RSDP.rsdt_address]

	; kontynuuj
	jmp	.standard

.extended:
	; pobierz adres tablicy XSDT na podstawie wskaźnika w nagłówku
	mov	rdi,	qword [rsi + ACPI_STRUCTURE_XSDP.xsdt_address]

	; ACPI 2.0+
	mov	r8b,	STATIC_FALSE

.standard:
	; komunikat błędu
	mov	rsi,	kernel_init_string_error_acpi

	; sprawdź sygnaturę tablicy RSDT
	cmp	dword [rdi + ACPI_STRUCTURE_RSDT_or_XSDT.signature],	"RSDT"
	je	.found	; rozpoznano

	; sprawdź sygnaturę tablicy XSDT
	cmp	dword [rdi + ACPI_STRUCTURE_RSDT_or_XSDT.signature],	"XSDT"
	jne	.error	; nie rozpoznano

	;=======================================================================

.found:
	; pobierz rozmiar tablicy wskaźników RSDT/XSDT
	mov	ecx,	dword [rdi + ACPI_STRUCTURE_RSDT_or_XSDT.length]
	sub	ecx,	ACPI_STRUCTURE_RSDT_or_XSDT.SIZE

	; przesuń wskaźnik na pierwszy wpis tablicy
	add	rdi,	ACPI_STRUCTURE_RSDT_or_XSDT.SIZE

	; wersja standardowa?
	cmp	r8b,	STATIC_TRUE
	je	.rsdt_pointers	; tak

.xsdt_pointers:
	; zamień na ilość wpisów
	shr	ecx,	STATIC_DIVIDE_BY_QWORD_shift

.xsdt_pointers_loop:
	; pobierz adres nagłówka wpisu
	mov	rsi,	qword [rdi]

	; sprawdź typ nagłówka
	call	.header

	; przesuń wskaźnik na następny wpis w tablicy XSDT
	add	rdi,	STATIC_QWORD_SIZE_byte

	; koniec wskaźników?
	dec	ecx
	jnz	.xsdt_pointers_loop	; nie

	; koniec przetwarzania tablic
	jmp	.summary

.rsdt_pointers:
	; zamień na ilość wpisów
	shr	ecx,	STATIC_DIVIDE_BY_DWORD_shift

.rsdt_pointers_loop:
	; pobierz adres nagłówka wpisu
	mov	esi,	dword [rdi]

	; sprawdź typ nagłówka
	call	.header

	; przesuń wskaźnik na następny wpis w tablicy RSDT
	add	rdi,	STATIC_DWORD_SIZE_byte

	; koniec wskaźników?
	dec	ecx
	jnz	.rsdt_pointers_loop	; nie

	; koniec przetwarzania tablic

.summary:
	; komunikat błędu
	mov	rsi,	kernel_init_string_error_apic

	; przetworzono choć jedną tablicę APIC?
	cmp	byte [kernel_apic_count],	STATIC_EMPTY
	je	.error	; nie, wyświetl komunikat błędu

	; komunikat błędu
	mov	rsi,	kernel_init_string_error_ioapic

	; przetworzono choć jedną tablicę I/O APIC?
	cmp	byte [kernel_init_ioapic_semaphore],	STATIC_FALSE
	je	.error	; nie, wyświetl komunikat błędu

	; kontynuuj inicjalizacje środowiska jądra systemu
	jmp	.end

;-------------------------------------------------------------------------------
.header:
	; nagłówek tablicy MADT (Multiple APIC Description Table)?
	cmp	dword [rsi + ACPI_STRUCTURE_MADT.signature],	"APIC"
	je	.madt	; tak, przetwórz

	; nie rozpoznano nagłówka, zignoruj
	ret

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

	; koniec podprocedury
	ret

;-------------------------------------------------------------------------------
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

;-------------------------------------------------------------------------------
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

.end:
