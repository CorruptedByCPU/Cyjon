;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
soler_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
;===============================================================================
soler_window:					dq	STATIC_EMPTY	; pozycja na osi X
						dq	STATIC_EMPTY	; pozycja na osi Y
						dq	SOLER_WINDOW_WIDTH_pixel	; szerokość okna
						dq	SOLER_WINDOW_HEIGHT_pixel	; wysokość okna
						dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna (uzupełnia Bosu)
.extra:						dq	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach (uzupełnia Bosu)
						dq	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_header | LIBRARY_BOSU_WINDOW_FLAG_border | LIBRARY_BOSU_WINDOW_FLAG_BUTTON_close
						dq	STATIC_EMPTY	; identyfikator okna (uzupełnia Bosu)
						db	5
						db	"Soler                          "	; wypełnij do 31 Bajtów znakami STATIC_SCANCODE_SPACE
						dq	STATIC_EMPTY	; szerokość okna w Bajtach (uzupełnia Bosu)
.elements:					;-------------------------------
.element_button_close:				; element "window close"
						;-------------------------------
						dd	LIBRARY_BOSU_ELEMENT_TYPE_button_close
						dq	.element_button_close_end - .element_button_close
						dq	soler.close
.element_button_close_end:			;-------------------------------
						; koniec elementów okna
						;-------------------------------
						dd	STATIC_EMPTY
soler_window_end:
