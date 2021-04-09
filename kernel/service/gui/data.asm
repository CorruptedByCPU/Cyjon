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
kernel_gui_event_task_manager_file	db	"/bin/console"
kernel_gui_event_task_manager_file_end:	db	" /bin/tm"
kernel_gui_event_task_manager_args_end:
kernel_gui_event_moko_file		db	"/bin/console"
kernel_gui_event_moko_file_end:		db	" /bin/moko"
kernel_gui_event_moko_args_end:
kernel_gui_event_soler_file		db	"/bin/soler"
kernel_gui_event_soler_file_end:
kernel_gui_event_taris_file		db	"/bin/taris"
kernel_gui_event_taris_file_end:
kernel_gui_event_mural_file		db	"/bin/mural"
kernel_gui_event_mural_file_end:

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

kernel_gui_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE	db	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

kernel_gui_taskbar_list_address		dq	STATIC_EMPTY
kernel_gui_taskbar_list_count		dq	STATIC_EMPTY

;===============================================================================
kernel_gui_window_workbench		dw	0	; pozycja na osi X
					dw	0	; pozycja na osi Y
					dw	STATIC_EMPTY	; szerokość okna
					dw	STATIC_EMPTY	; wysokość okna
					dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna
.extra:					dd	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach
					dw	LIBRARY_BOSU_WINDOW_FLAG_fixed_xy | LIBRARY_BOSU_WINDOW_FLAG_fixed_z | LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
					dq	STATIC_EMPTY	; identyfikator okna nadawany przez menedżer okien
					db	9
					db	"Workbench                      "	; wypełnij do 31 Bajtów znakami STATIC_SCANCODE_SPACE
					dd	STATIC_EMPTY	; szerokość okna w Bajtach (uzupełnia Bosu)
					dd	STATIC_COLOR_black	; kolor tła okna

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

kernel_gui_window_taskbar_modify_time	dq	STATIC_EMPTY

;===============================================================================
kernel_gui_window_taskbar		dw	0	; pozycja na osi X
					dw	STATIC_EMPTY	; pozycja na osi Y
					dw	STATIC_EMPTY	; szerokość okna
					dw	KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel	; wysokość okna
					dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna
.extra:					dd	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach
					dw	LIBRARY_BOSU_WINDOW_FLAG_fixed_xy | LIBRARY_BOSU_WINDOW_FLAG_fixed_z | LIBRARY_BOSU_WINDOW_FLAG_arbiter | LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush | LIBRARY_BOSU_WINDOW_FLAG_unregistered
					dq	STATIC_EMPTY	; identyfikator okna nadawany przez menedżer okien
					db	7
					db	"Taskbar                        "	; wypełnij do 31 Bajtów znakami STATIC_SCANCODE_SPACE
					dd	STATIC_EMPTY	; szerokość okna w Bajtach (uzupełnia Bosu)
					dd	STATIC_COLOR_black	; kolor tła okna
.elements:				;---------------------------------------
					; element "łańcuch 0"
					;---------------------------------------
.element_chain_0:			db	LIBRARY_BOSU_ELEMENT_TYPE_chain
					dw	STATIC_EMPTY	; rozmiar przestrzeni łańcucha w Bajtach
					dq	STATIC_EMPTY	; adres przestrzeni łańcucha
					;---------------------------------------
					; element "etykieta zegar"
					;---------------------------------------
.element_label_clock:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
					dw	.element_label_clock_end - .element_label_clock ; rozmiar elementu w Bajtach
					dw	0	; pozycja na osi X względem okna
					dw	0	; pozycja na osi Y względem okna
					dw	LIBRARY_FONT_WIDTH_pixel * (.element_label_clock_end - .element_label_clock_string_hour)	; szerokość elementu w pikselach
					dw	18	; wysokość elementu w pikselach
					dq	STATIC_EMPTY	; wskaźnik procedury obsługi zdarzenia
					dd	STATIC_COLOR_white
					dd	STATIC_COLOR_black
					db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_center
					db	.element_label_clock_end - .element_label_clock_string   ; rozmiar ciągu w znakach
.element_label_clock_string:		db	" "
.element_label_clock_string_hour:	db	"00"
.element_label_clock_char_colon:	db	":"
.element_label_clock_string_minute:	db	"00  "	; dlaczego dwie spacje?
.element_label_clock_end:		;---------------------------------------
					; koniec elementów okna
					;---------------------------------------
					db	LIBRARY_BOSU_ELEMENT_TYPE_none
kernel_gui_window_taskbar_end:

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

;===============================================================================
kernel_gui_window_menu			dw	160	; pozycja na osi X względem wskaźnika kursora
					dw	80	; pozycja na osi Y względem wskaźnika kursora
					dw	STATIC_EMPTY	; szerokość okna względem zawartości elementów
					dw	STATIC_EMPTY	; wysokość okna względem zawartości elementów
					dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna
.extra:					dd	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach
					dw	LIBRARY_BOSU_WINDOW_FLAG_fragile | LIBRARY_BOSU_WINDOW_FLAG_unregistered | LIBRARY_BOSU_WINDOW_FLAG_border | LIBRARY_BOSU_WINDOW_FLAG_header
					dq	STATIC_EMPTY	; identyfikator okna nadawany przez menedżer okien
					db	4
					db	"Menu                           "	; wypełnij do 31 Bajtów znakami STATIC_SCANCODE_SPACE
					dd	STATIC_EMPTY	; szerokość okna w Bajtach (uzupełnia Bosu)
					dd	LIBRARY_BOSU_WINDOW_BACKGROUND_color	; kolor tła okna
.elements:				;---------------------------------------
					; element "Console"
					;---------------------------------------
.element_console:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
					dw	.element_console_end - .element_console ; rozmiar elementu w Bajtach
					dw	0	; pozycja na osi X względem przestrzeni danych okna
					dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel	; pozycja na osi Y względem przestrzeni danych okna
					dw	((.element_console_end - .element_console_string) * LIBRARY_FONT_WIDTH_pixel)	; szerokość elementu
					dw	KERNEL_GUI_WINDOW_MENU_ELEMENT_HEIGHT_pixel	; wysokość elementu
					dq	kernel_gui_event_console
					dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
					dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
					db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
					db	.element_console_end - .element_console_string
.element_console_string:		db	" Console "
.element_console_end:			;---------------------------------------
					; element "Moko"
					;---------------------------------------
.element_moko:				db	LIBRARY_BOSU_ELEMENT_TYPE_label
					dw	.element_moko_end - .element_moko ; rozmiar elementu w Bajtach
					dw	0	; pozycja na osi X względem przestrzeni danych okna
					dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + (KERNEL_GUI_WINDOW_MENU_ELEMENT_HEIGHT_pixel)	; pozycja na osi Y względem przestrzeni danych okna
					dw	((.element_moko_end - .element_moko_string) * LIBRARY_FONT_WIDTH_pixel)	; szerokość elementu
					dw	KERNEL_GUI_WINDOW_MENU_ELEMENT_HEIGHT_pixel	; wysokość elementu
					dq	kernel_gui_event_moko
					dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
					dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
					db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
					db	.element_moko_end - .element_moko_string
.element_moko_string:			db	" Moko "
.element_moko_end:			;---------------------------------------
					; element "Soler"
					;---------------------------------------
.element_soler:				db	LIBRARY_BOSU_ELEMENT_TYPE_label
					dw	.element_soler_end - .element_soler ; rozmiar elementu w Bajtach
					dw	0	; pozycja na osi X względem przestrzeni danych okna
					dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + (KERNEL_GUI_WINDOW_MENU_ELEMENT_HEIGHT_pixel * 0x02)	; pozycja na osi Y względem przestrzeni danych okna
					dw	((.element_soler_end - .element_soler_string) * LIBRARY_FONT_WIDTH_pixel)	; szerokość elementu
					dw	KERNEL_GUI_WINDOW_MENU_ELEMENT_HEIGHT_pixel	; wysokość elementu
					dq	kernel_gui_event_soler
					dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
					dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
					db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
					db	.element_soler_end - .element_soler_string
.element_soler_string:			db	" Soler "
.element_soler_end:			;---------------------------------------
					; element "Taris"
					;---------------------------------------
.element_taris:				db	LIBRARY_BOSU_ELEMENT_TYPE_label
					dw	.element_taris_end - .element_taris ; rozmiar elementu w Bajtach
					dw	0	; pozycja na osi X względem przestrzeni danych okna
					dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + (KERNEL_GUI_WINDOW_MENU_ELEMENT_HEIGHT_pixel * 0x03)	; pozycja na osi Y względem przestrzeni danych okna
					dw	((.element_taris_end - .element_taris_string) * LIBRARY_FONT_WIDTH_pixel)	; szerokość elementu
					dw	KERNEL_GUI_WINDOW_MENU_ELEMENT_HEIGHT_pixel	; wysokość elementu
					dq	kernel_gui_event_taris
					dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
					dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
					db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
					db	.element_taris_end - .element_taris_string
.element_taris_string:			db	" Taris "
.element_taris_end:			;---------------------------------------
					; element "Task Manager"
					;---------------------------------------
.element_tm:				db	LIBRARY_BOSU_ELEMENT_TYPE_label
					dw	.element_tm_end - .element_tm ; rozmiar elementu w Bajtach
					dw	0	; pozycja na osi X względem przestrzeni danych okna
					dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + (KERNEL_GUI_WINDOW_MENU_ELEMENT_HEIGHT_pixel * 0x04)	; pozycja na osi Y względem przestrzeni danych okna
					dw	((.element_tm_end - .element_tm_string) * LIBRARY_FONT_WIDTH_pixel)	; szerokość elementu
					dw	KERNEL_GUI_WINDOW_MENU_ELEMENT_HEIGHT_pixel	; wysokość elementu
					dq	kernel_gui_event_task_manager
					dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
					dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
					db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
					db	.element_tm_end - .element_tm_string
.element_tm_string:			db	" Task Manager "
.element_tm_end:			;---------------------------------------
					; koniec elementów okna
					;---------------------------------------
					db	LIBRARY_BOSU_ELEMENT_TYPE_none
kernel_gui_window_menu_end:
