;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
;===============================================================================
mural_window:					dw	STATIC_EMPTY	; pozycja na osi X
						dw	STATIC_EMPTY	; pozycja na osi Y
						dw	MUTSU_WINDOW_WIDTH_pixel	; szerokość okna
						dw	MUTSU_WINDOW_HEIGHT_pixel	; wysokość okna
						dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna (uzupełnia Bosu)
.extra:						dd	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach (uzupełnia Bosu)
						dw	LIBRARY_BOSU_WINDOW_FLAG_transparent | LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_border
						dq	STATIC_EMPTY	; identyfikator okna (uzupełnia Bosu)
						db	5
						db	"Mural                          "	; wypełnij do 31 Bajtów znakami STATIC_SCANCODE_SPACE
						dd	STATIC_EMPTY	; szerokość okna w Bajtach (uzupełnia Bosu)
						dd	0xD0000000	; kolor tła okna
.elements:					;-------------------------------
						; koniec elementów okna
						;-------------------------------
						db	STATIC_EMPTY
mural_window_end:
