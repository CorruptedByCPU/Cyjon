;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_INIT_MEMORY_MULTIBOOT_FLAG_memory_map	equ	6

struc	KERNEL_INIT_MEMORY_MULTIBOOT_STRUCTURE_MEMORY_MAP
	.size		resb	4
	.address	resb	8
	.limit		resb	8
	.type		resb	4
	.SIZE:
endstruc

;===============================================================================
; wejście:
;	ebx - wskaźnik do nagłówka Multiboot
kernel_init_memory:
	; ustaw komunikat błędu
	mov	ecx,	kernel_init_string_error_memory_end - kernel_init_string_error_memory
	mov	rsi,	kernel_init_string_error_memory

	; nagłówek udostępnia mapę pamięci BIOSu?
	bt	dword [ebx + HEADER_multiboot.flags],	KERNEL_INIT_MEMORY_MULTIBOOT_FLAG_memory_map
	jnc	kernel_panic	; błąd krytyczny

	; pobierz rozmiar i adres tablicy mapy pamięci z nagłówka Multiboot
	mov	ecx,	dword [ebx + HEADER_multiboot.mmap_length]
	mov	ebx,	dword [ebx + HEADER_multiboot.mmap_addr]

.search:
	; odszukaj przestrzeń pamięci rozpoczynającą się od adresu KERNEL_BASE_address
	cmp	qword [ebx + KERNEL_INIT_MEMORY_MULTIBOOT_STRUCTURE_MEMORY_MAP.address],	KERNEL_BASE_address
	je	.found	; odnaleziono

	; następny wpis z tablicy mapy pamięci
	add	ebx,	KERNEL_INIT_MEMORY_MULTIBOOT_STRUCTURE_MEMORY_MAP.SIZE

	; koniec wpisów tablicy?
	sub	ecx,	KERNEL_INIT_MEMORY_MULTIBOOT_STRUCTURE_MEMORY_MAP.SIZE
	jnz	.search	; nie

	; ustaw komunikat błędu: uszkodzona tablica mapy pamięci
	mov	ecx,	kernel_init_string_error_memory_end - kernel_init_string_error_memory
	mov	rsi,	kernel_init_string_error_memory
	call	kernel_panic

.found:
	; pobierz i zamień rozmiar przestrzeni na ilość stron
	mov	rcx,	qword [rbx + KERNEL_INIT_MEMORY_MULTIBOOT_STRUCTURE_MEMORY_MAP.limit]
	shr	rcx,	STATIC_DIVIDE_BY_PAGE_shift	; resztę z dzielenia porzucamy (niepełna strona jest bezużyteczna)

	; zachowaj informację o ilości dostępnych stron (całkowitej i aktualnej)
	mov	qword [kernel_page_total_count],	rcx
	mov	qword [kernel_page_free_count],	rcx

	; binarną mapę pamięci tworzymy za kodem jądra systemu
	mov	rdi,	kernel_end
	call	library_page_align_up

	; zachowaj adres binarnej mapy pamięci jądra systemu
	mov	qword [kernel_memory_map_address],	rdi

	; zamień ilość stron na "zestawy" po 8 bitów
	shr	rcx,	STATIC_DIVIDE_BY_8_shift	; w tym przypadku możemy stracić do 7 stron
	; zastosowane w celu uproszenia kodu

	; zachowaj ilość stron
	push	rcx

	; wyczyść przestrzeń binarnej mapy pamięci
	call	library_page_from_size
	call	kernel_page_drain_few

	; przywróć ilość stron
	pop	rcx

	; wypełnij binarną mapę pamięci
	mov	al,	STATIC_MAX_unsigned
	rep	stosb

	; zachowaj adres końca binarnej mapy pamięci
	mov	qword [kernel_memory_map_address_end],	rdi

	; oznacz te strony jako zajęte, w których znajduje się kod jądra systemu i binarna mapa pamięci

	; wylicz rozmiar wykorzystanej przestrzeni w stronach
	call	library_page_align_up
	sub	rdi,	KERNEL_BASE_address
	shr	rdi,	STATIC_DIVIDE_BY_PAGE_shift

 	; jako, że pobierając dostępną stronę z binarnej mapy pamięci, zawsze otrzymujemy pierwszą wolną
 	; możemy uprościć sposób oznaczenia pierwszych N zajętych

	; zarezerwuj przestrzeń o danym rozmiarze w binarnej mapie pamięci jądra systemu
	mov	rcx,	rdi
	call	kernel_memory_alloc
