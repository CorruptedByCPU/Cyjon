;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

;===============================================================================
service_cero_window_workbench		dq	0	; pozycja na osi X
					dq	0	; pozycja na osi Y
					dq	STATIC_EMPTY	; szerokość okna
					dq	STATIC_EMPTY	; wysokość okna
					dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna
.extra:					dq	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach
					dq	SERVICE_DESU_OBJECT_FLAG_fixed_xy | SERVICE_DESU_OBJECT_FLAG_fixed_z | SERVICE_DESU_OBJECT_FLAG_visible | SERVICE_DESU_OBJECT_FLAG_flush

;===============================================================================
service_cero_window_menu		dq	STATIC_EMPTY	; pozycja na osi X względem wskaźnika kursora
					dq	STATIC_EMPTY	; pozycja na osi Y względem wskaźnika kursora
					dq	STATIC_EMPTY	; szerokość okna względem zawartości elementów
					dq	STATIC_EMPTY	; wysokość okna względem zawartości elementów
					dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna
.extra:					dq	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach
					dq	LIBRARY_BOSU_WINDOW_FLAG_header | LIBRARY_BOSU_WINDOW_FLAG_fragile | SERVICE_DESU_OBJECT_FLAG_visible | SERVICE_DESU_OBJECT_FLAG_flush
					dq	STATIC_EMPTY	; szerokosć okna w Bajtach
.elements:
					;---------------------------------------
					; element "nagłówek"
					;---------------------------------------
.element_header:			dd	LIBRARY_BOSU_ELEMENT_TYPE_header
					dq	.element_header_end - .element_header	; rozmiar elementu
					db	.element_header_end - .element_header_string
.element_header_string:			db	"Menu"
.element_header_end:
					;---------------------------------------
					; element "przycisk 0"
					;---------------------------------------
.element_button_0:			dd	LIBRARY_BOSU_ELEMENT_TYPE_button
					dq	.element_button_0_end - .element_button_0 ; rozmiar elementu w Bajtach
					dq	0	; pozycja na osi X względem przestrzeni danych okna
					dq	0	; pozycja na osi Y względem przestrzeni danych okna
					dq	(.element_button_0_end - .element_button_0_string) * LIBRARY_BOSU_FONT_WIDTH_pixel	; szerokość elementu
					dq	LIBRARY_BOSU_FONT_HEIGHT_pixel	; wysokość elementu
					dq	STATIC_EMPTY	; wskaźnik do procedury obsługującej wyjątek
					db	.element_button_0_end - .element_button_0_string
.element_button_0_string:		db	" Console "
.element_button_0_end:
					;---------------------------------------
					; koniec elementów okna
					;---------------------------------------
					dd	STATIC_EMPTY
service_cero_window_menu_end:
