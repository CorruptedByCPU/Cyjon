;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

console_shell_file				db	"/bin/shell"
console_shell_file_end:

console_string_sequence_color_black		db	STATIC_SEQUENCE_COLOR_BLACK
console_string_sequence_color_red		db	STATIC_SEQUENCE_COLOR_RED
console_string_sequence_color_green		db	STATIC_SEQUENCE_COLOR_GREEN
console_string_sequence_color_brown		db	STATIC_SEQUENCE_COLOR_BROWN
console_string_sequence_color_blue		db	STATIC_SEQUENCE_COLOR_BLUE
console_string_sequence_color_magenta		db	STATIC_SEQUENCE_COLOR_MAGENTA
console_string_sequence_color_cyan		db	STATIC_SEQUENCE_COLOR_CYAN
console_string_sequence_color_gray_light	db	STATIC_SEQUENCE_COLOR_GRAY_LIGHT
console_string_sequence_color_gray		db	STATIC_SEQUENCE_COLOR_GRAY
console_string_sequence_color_red_light		db	STATIC_SEQUENCE_COLOR_RED_LIGHT
console_string_sequence_color_green_light	db	STATIC_SEQUENCE_COLOR_GREEN_LIGHT
console_string_sequence_color_yellow		db	STATIC_SEQUENCE_COLOR_YELLOW
console_string_sequence_color_blue_light	db	STATIC_SEQUENCE_COLOR_BLUE_LIGHT
console_string_sequence_color_magenta_light	db	STATIC_SEQUENCE_COLOR_MAGENTA_LIGHT
console_string_sequence_color_cyan_light	db	STATIC_SEQUENCE_COLOR_CYAN_LIGHT
console_string_sequence_color_white		db	STATIC_SEQUENCE_COLOR_WHITE

console_table_color:				dd	STATIC_COLOR_black
						dd	STATIC_COLOR_red
						dd	STATIC_COLOR_green
						dd	STATIC_COLOR_brown
						dd	STATIC_COLOR_blue
						dd	STATIC_COLOR_magenta
						dd	STATIC_COLOR_cyan
						dd	STATIC_COLOR_gray_light
						dd	STATIC_COLOR_gray
						dd	STATIC_COLOR_red_light
						dd	STATIC_COLOR_green_light
						dd	STATIC_COLOR_yellow
						dd	STATIC_COLOR_blue_light
						dd	STATIC_COLOR_magenta_light
						dd	STATIC_COLOR_cyan_light
						dd	STATIC_COLOR_white

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
console_cache_address				dq	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
console_process_pid				dq	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
console_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
console_stream_meta:				dw	CONSOLE_WINDOW_WIDTH_char
						dw	CONSOLE_WINDOW_HEIGHT_char
						dw	STATIC_EMPTY	; x
						dw	STATIC_EMPTY	; y

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
;===============================================================================
console_window					dw	STATIC_EMPTY	; pozycja na osi X
						dw	STATIC_EMPTY	; pozycja na osi Y
						dw	CONSOLE_WINDOW_WIDTH_pixel	; szerokość okna
						dw	CONSOLE_WINDOW_HEIGHT_pixel	; wysokość okna
						dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna (uzupełnia Bosu)
.extra:						dd	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach (uzupełnia Bosu)
						dw	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_header | LIBRARY_BOSU_WINDOW_FLAG_border | LIBRARY_BOSU_WINDOW_FLAG_BUTTON_close
						dq	STATIC_EMPTY	; identyfikator okna (uzupełnia Bosu)
						db	7
						db	"Console                        "	; wypełnij do 31 Bajtów znakami STATIC_SCANCODE_SPACE
						dd	STATIC_EMPTY	; szerokość okna w Bajtach (uzupełnia Bosu)
						dd	STATIC_COLOR_black	; kolor tła okna
.elements:					;-------------------------------
.element_button_close:				; element "window close"
						;-------------------------------
						db	LIBRARY_BOSU_ELEMENT_TYPE_button_close
						dw	.element_button_close_end - .element_button_close
						dq	console.close
.element_button_close_end:			;-------------------------------
						; element "terminal"
						;-------------------------------
.element_terminal:				db	LIBRARY_BOSU_ELEMENT_TYPE_draw
						dw	.element_terminal_end - .element_terminal
						dw	0	; pozycja na osi X względem przestrzeni danych okna
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	CONSOLE_WINDOW_WIDTH_pixel
						dw	CONSOLE_WINDOW_HEIGHT_pixel - LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dq	STATIC_EMPTY	; brak obsługi wyjątku
						dq	STATIC_EMPTY	; adres przestrzeni elementu (uzupełnia Bosu)
.element_terminal_end:				;-------------------------------
						; koniec elementów okna
						;-------------------------------
						db	STATIC_EMPTY
console_window_end:

;===============================================================================
console_terminal_properties			dq	CONSOLE_WINDOW_WIDTH_pixel	; szerokość w pikselach
						dq	CONSOLE_WINDOW_HEIGHT_pixel - LIBRARY_BOSU_HEADER_HEIGHT_pixel	; wysokość w pikselach
						dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych terminala
						dq	(CONSOLE_WINDOW_WIDTH_pixel * (CONSOLE_WINDOW_HEIGHT_pixel - LIBRARY_BOSU_HEADER_HEIGHT_pixel)) << KERNEL_VIDEO_DEPTH_shift	; rozmiar przestrzeni w Bajtach
						dq	STATIC_NOTHING	; scanline w Bajtach - uzupełniane podczas inicjalizacji programu
						dq	STATIC_EMPTY	; wskaźnik pozycji wirtualnego kursora w przestrzeni danych terminala
						dq	STATIC_EMPTY	; szerokość terminala w znakach
						dq	STATIC_EMPTY	; wysokość terminala w znakach
						dq	STATIC_EMPTY	; scanline_char
						dq	STATIC_EMPTY	; pozycja kursora na osi X.Y
						dq	STATIC_EMPTY	; blokada wirtualnego kursora
						dd	STATIC_COLOR_default	; kolor czcionki
						dd	STATIC_COLOR_BACKGROUND_default	; kolor tła

console_terminal_cursor_position_save		dq	STATIC_EMPTY
