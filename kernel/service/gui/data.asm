;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

kernel_gui_pid				dq	STATIC_EMPTY

kernel_gui_clock_last_state		dq	STATIC_EMPTY
kernel_gui_clock_colon			db	STATIC_SCANCODE_SPACE

kernel_gui_background_mixer		dd	0x001B1B1B, 0x00212121

kernel_gui_event_console_file		db	"/bin/console"
kernel_gui_event_console_file_end:
kernel_gui_event_soler_file		db	"/bin/soler"
kernel_gui_event_soler_file_end:

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

kernel_gui_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE	db	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

kernel_gui_taskbar_list_address		dq	STATIC_EMPTY
kernel_gui_taskbar_list_count		dq	STATIC_EMPTY

;===============================================================================
kernel_gui_window_workbench		dq	0	; pozycja na osi X
					dq	0	; pozycja na osi Y
					dq	STATIC_EMPTY	; szerokość okna
					dq	STATIC_EMPTY	; wysokość okna
					dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna
.extra:					dq	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach
					dq	LIBRARY_BOSU_WINDOW_FLAG_fixed_xy | LIBRARY_BOSU_WINDOW_FLAG_fixed_z | LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
					dq	STATIC_EMPTY	; identyfikator okna nadawany przez menedżer okien
					db	9
					db	"Workbench                      "	; wypełnij do 31 Bajtów znakami STATIC_SCANCODE_SPACE
					dq	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

;===============================================================================
kernel_gui_window_taskbar_modify_time	dq	STATIC_EMPTY
kernel_gui_window_taskbar		dq	0	; pozycja na osi X
					dq	STATIC_EMPTY	; pozycja na osi Y
					dq	STATIC_EMPTY	; szerokość okna
					dq	KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel	; wysokość okna
					dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna
.extra:					dq	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach
					dq	LIBRARY_BOSU_WINDOW_FLAG_fixed_xy | LIBRARY_BOSU_WINDOW_FLAG_fixed_z | LIBRARY_BOSU_WINDOW_FLAG_arbiter | LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush | LIBRARY_BOSU_WINDOW_FLAG_unregistered
					dq	STATIC_EMPTY	; identyfikator okna nadawany przez menedżer okien
					db	7
					db	"Taskbar                        "	; wypełnij do 31 Bajtów znakami STATIC_SCANCODE_SPACE
					dq	STATIC_EMPTY	; szerokość okna w Bajtach
.elements:				;---------------------------------------
					; element "łańcuch 0"
					;---------------------------------------
.element_chain_0:			dd	LIBRARY_BOSU_ELEMENT_TYPE_chain
					dq	STATIC_EMPTY	; rozmiar przestrzeni łańcucha w Bajtach
					dq	STATIC_EMPTY	; adres przestrzeni łańcucha
					;---------------------------------------
					; element "etykieta zegar"
					;---------------------------------------
.element_label_clock:			dd	LIBRARY_BOSU_ELEMENT_TYPE_label
					dq	.element_label_clock_end - .element_label_clock ; rozmiar elementu w Bajtach
					dq	0	; pozycja na osi X względem okna
					dq	0	; pozycja na osi Y względem okna
					dq	LIBRARY_FONT_WIDTH_pixel * (.element_label_clock_end - .element_label_clock_string_hour)	; szerokość elementu w pikselach
					dq	18	; wysokość elementu w pikselach
					dq	STATIC_EMPTY	; wskaźnik procedury obsługi zdarzenia
					db	.element_label_clock_end - .element_label_clock_string   ; rozmiar ciągu w znakach
.element_label_clock_string:		db	" ",
.element_label_clock_string_hour:	db	"00"
.element_label_clock_char_colon:	db	":"
.element_label_clock_string_minute:	db	"00  "	; dlaczego dwie spacje?
.element_label_clock_end:		;---------------------------------------
					; koniec elementów okna
					;---------------------------------------
					dd	LIBRARY_BOSU_ELEMENT_TYPE_none
kernel_gui_window_taskbar_end:

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

;===============================================================================
kernel_gui_window_menu			dq	160	; pozycja na osi X względem wskaźnika kursora
					dq	80	; pozycja na osi Y względem wskaźnika kursora
					dq	STATIC_EMPTY	; szerokość okna względem zawartości elementów
					dq	STATIC_EMPTY	; wysokość okna względem zawartości elementów
					dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna
.extra:					dq	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach
					dq	LIBRARY_BOSU_WINDOW_FLAG_fragile | LIBRARY_BOSU_WINDOW_FLAG_unregistered | LIBRARY_BOSU_WINDOW_FLAG_border
					dq	STATIC_EMPTY	; identyfikator okna nadawany przez menedżer okien
					db	4
					db	"Menu                           "	; wypełnij do 31 Bajtów znakami STATIC_SCANCODE_SPACE
					dq	STATIC_EMPTY	; szerokosć okna w Bajtach
.elements:				;---------------------------------------
					; element "label 0"
					;---------------------------------------
.element_label_0:			dd	LIBRARY_BOSU_ELEMENT_TYPE_label
					dq	.element_label_0_end - .element_label_0 ; rozmiar elementu w Bajtach
					dq	1	; pozycja na osi X względem przestrzeni danych okna
					dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel	; pozycja na osi Y względem przestrzeni danych okna
					dq	((.element_label_0_end - .element_label_0_string) * LIBRARY_FONT_WIDTH_pixel) - 0x02	; szerokość elementu
					dq	0x10	; wysokość elementu
					dq	kernel_gui_event_console
					db	.element_label_0_end - .element_label_0_string
.element_label_0_string:		db	" Console "
.element_label_0_end:			;---------------------------------------
					; element "label 1"
					;---------------------------------------
.element_label_1:			dd	LIBRARY_BOSU_ELEMENT_TYPE_label
					dq	.element_label_1_end - .element_label_1 ; rozmiar elementu w Bajtach
					dq	1	; pozycja na osi X względem przestrzeni danych okna
					dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 0x10	; pozycja na osi Y względem przestrzeni danych okna
					dq	((.element_label_1_end - .element_label_1_string) * LIBRARY_FONT_WIDTH_pixel) - 0x02	; szerokość elementu
					dq	0x10	; wysokość elementu
					dq	kernel_gui_event_soler
					db	.element_label_1_end - .element_label_1_string
.element_label_1_string:		db	" Soler "
.element_label_1_end:			;---------------------------------------
					; koniec elementów okna
					;---------------------------------------
					dd	LIBRARY_BOSU_ELEMENT_TYPE_none
kernel_gui_window_menu_end:
