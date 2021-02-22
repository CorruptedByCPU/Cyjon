;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	; przygotuj przestrzeń pod tablicę kolorów
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_alloc
	mov	ecx,	STATIC_PAGE_SIZE_byte	; jedna strona wystarczy
	int	KERNEL_SERVICE

	; zachowaj wskaźnik
	mov	qword [taris_playground_colors_table],	rdi

	; utwórz okno
	mov	rsi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu
	jc	taris.close	; brak wystarczającej przestrzeni pamięci

	; uzupełnij właściwości danych biblioteki RGL dla przestrzeni gry
	mov	r8,	taris_rgl_playground_properties
	mov	rax,	qword [taris_window.element_playground + LIBRARY_BOSU_STRUCTURE_ELEMENT_DRAW.address]
	mov	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.address],	rax

	; inicjalizuj bibliotekę
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl
	jc	taris.close	; brak wystarczającej przestrzeni pamięci

	; uzupełnij właściwości danych biblioteki RGL dla przestrzeni przewidywania
	mov	r8,	taris_rgl_foresee_properties
	mov	rax,	qword [taris_window.element_foresee + LIBRARY_BOSU_STRUCTURE_ELEMENT_DRAW.address]
	mov	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.address],	rax

	; inicjalizuj bibliotekę
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl
	jc	taris.close	; brak wystarczającej przestrzeni pamięci

.restart:
	; wyczyść przestrzeń gry
	call	taris_show_empty

	; ilość punktów
	mov	dword [taris_points_total],	STATIC_EMPTY

	; ilość skasowanych linii
	mov	dword [taris_lines],	STATIC_EMPTY

	; aktualizuj interfejs gry
	call	taris_interface

	; wylosuj pierwszy klocek
	call	taris_random_block
