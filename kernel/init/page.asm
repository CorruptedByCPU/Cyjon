;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

kernel_init_page:
	; przygotuj miejsce na tablicę PML4 jądra systemu
	call	kernel_memory_alloc_page
	jc	kernel_panic_memory

	; wyczyść wszystkie wpisy w tablicy PML4 i zapamiętaj jej adres
	call	kernel_page_drain
	mov	qword [kernel_page_pml4_address],	rdi

	; strona wykorzystana w tablicach stronicowania
	inc	qword [kernel_page_paged_count]

	; mapuj w tablicach stronicowania przestrzeń pamięci fizycznej RAM opisanej w binarnej mapie pamięci
	mov	eax,	KERNEL_BASE_address	; początek przestrzeni
	; oznacz przestrzeń jako dostępną i modyfikowalną dla jądra systemu
	mov	bx,	KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
	mov	rcx,	qword [kernel_page_total_count]	; rozmiar przestrzeni w stronach
	mov	r11,	rdi	; miejsce docelowe tablicy PML4 jądra systemu
	call	kernel_page_map_physical	; opisz 1:1
	jc	kernel_panic_memory

	; utwórz stos/"stos kontekstu" dla jądra systemu na końcu pierwszej połowy przestrzeni pamięci logicznej
	; jądro systemu otrzyma pierwszą połowę przestrzeni pamięci logicznej
	mov	rax,	KERNEL_STACK_address
	mov	ecx,	KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	call	kernel_page_map_logical
	jc	kernel_panic_memory

	; https://forum.osdev.org/viewtopic.php?f=1&t=29034
	; https://wiki.osdev.org/Paging
	; https://forum.osdev.org/viewtopic.php?f=1&t=23223
	; https://forums.freebsd.org/threads/xorg-vesa-driver-massive-speedup-using-mtrr-write-combine.46723/
	; https://stackoverflow.com/questions/13297178/how-mtrr-registers-implemented
	; cdn.
	;
	; mapuj przestrzeń pamięci fizycznej karty graficznej
	mov	rax,	qword [kernel_video_base_address]
	or	bx,	KERNEL_PAGE_FLAG_write_through | KERNEL_PAGE_FLAG_cache_disable
	mov	rcx,	qword [kernel_video_size_byte]
	call	library_page_from_size
	call	kernel_page_map_physical
	jc	kernel_panic_memory

	; mapuj przestrzeń pamięci fizycznej tablicy APIC
	mov	rax,	qword [kernel_apic_base_address]
	mov	bx,	KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
	mov	ecx,	dword [kernel_apic_size]	; rozmiar przestrzeni w Bajtach
	call	library_page_from_size
	call	kernel_page_map_physical
	jc	kernel_panic_memory

	; mapuj przestrzeń pamięci fizycznej tablicy I/O APIC
	mov	eax,	dword [kernel_io_apic_base_address]
	mov	ecx,	STATIC_PAGE_SIZE_byte >> STATIC_PAGE_SIZE_shift
	call	kernel_page_map_physical
	jc	kernel_panic_memory

	; przeładuj stronicowanie na własne/nowo utworzone
	mov	rax,	rdi
	mov	cr3,	rax

	; ustawiamy wskaźnik szczytu stosu na koniec nowego stosu jądra systemu
	mov	rsp,	KERNEL_STACK_pointer
