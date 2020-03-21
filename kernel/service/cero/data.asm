;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

;===============================================================================
service_cero_window_workbench		dq	0	; x
					dq	0	; y
					dq	STATIC_EMPTY	; szerokość
					dq	STATIC_EMPTY	; wysokosć
					dq	STATIC_EMPTY	; adres przestrzeni danych
.extra:					dq	STATIC_EMPTY	; rozmiar w Bajtach
					dq	SERVICE_DESU_OBJECT_FLAG_fixed_xy | SERVICE_DESU_OBJECT_FLAG_fixed_z | SERVICE_DESU_OBJECT_FLAG_visible | SERVICE_DESU_OBJECT_FLAG_flush

;===============================================================================
service_cero_window_menu		dq	STATIC_EMPTY
					dq	STATIC_EMPTY
					dq	STATIC_EMPTY
					dq	STATIC_EMPTY
					dq	STATIC_EMPTY
.extra:					dq	STATIC_EMPTY
					dq	LIBRARY_BOSU_WINDOW_FLAG_header | LIBRARY_BOSU_WINDOW_FLAG_fragile
.elements:
					;---------------------------------------
					; element "nagłówek"
					;---------------------------------------
.element_header:			dd	LIBRARY_BOSU_ELEMENT_TYPE_header
					dq	.element_header_end - .element_header
					db	.element_header_end - .element_header_string
.element_header_string:			db	"Menu"
.element_header_end:
					;---------------------------------------
					; element "etykieta 0"
					;---------------------------------------
.element_label_0:			dd	LIBRARY_BOSU_ELEMENT_TYPE_label
					dq	.element_label_0_end - .element_label_0 ; rozmiar elementu w Bajtach
					dq	0
					dq	0
					dq	72
					dq	16
					dq	STATIC_EMPTY
					db	.element_label_0_end - .element_label_0_string
.element_label_0_string:		db	" Console "
.element_label_0_end:
					;---------------------------------------
					; end of elements
					;---------------------------------------
					dd	STATIC_EMPTY
service_cero_window_menu_end:
