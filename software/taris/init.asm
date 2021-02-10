;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	; utwórz okno
	mov	rsi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu
	jc	taris.close	; brak wystarczającej przestrzeni pamięci

	; ustaw zmienną globalną
	mov	r8,	taris_rgl_properties

	; uzupełnij właściwości danych biblioteki RGL
	mov	rax,	qword [taris_window.element_playground + LIBRARY_BOSU_STRUCTURE_ELEMENT_DRAW.address]
	mov	qword [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.address],	rax

	; inicjalizuj bibliotekę
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl
	jc	taris.close	; brak wystarczającej przestrzeni pamięci
