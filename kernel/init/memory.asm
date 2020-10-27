;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

struc	KERNEL_INIT_MEMORY_STRUCTURE_MEMORY_MAP
	.address	resb	8
	.limit		resb	8
	.type		resb	4
	.SIZE:
endstruc

;===============================================================================
; wejście:
;	ebx - wskaźnik do tablicy mapy pamieci
kernel_init_memory:
	; odszukaj przestrzeń pamięci rozpoczynającą się od adresu KERNEL_BASE_address
	cmp	qword [ebx + KERNEL_INIT_MEMORY_STRUCTURE_MEMORY_MAP.address],	KERNEL_BASE_address
	je	.found	; odnaleziono

	; następny wpis z tablicy mapy pamięci
	add	ebx,	KERNEL_INIT_MEMORY_STRUCTURE_MEMORY_MAP.SIZE

	; koniec wpisów?
	cmp	qword [ebx],	STATIC_EMPTY
	jne	kernel_init_memory	; nie

	; komunikat błędu
	mov	rsi,	kernel_init_string_error_memory
	call	kernel_panic

.found:
	; pobierz i zamień rozmiar przestrzeni na ilość stron
	mov	rcx,	qword [rbx + KERNEL_INIT_MEMORY_STRUCTURE_MEMORY_MAP.limit]
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

	; oznacz N pierwszych stron w binarnej mapie pamięci jako zajęte
	mov	rcx,	rdi
	mov	rsi,	qword [kernel_memory_map_address]
	call	kernel_memory_secure
