;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
taris_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY

taris_microtime					dq	819	; 1024 == 1 sekunda
taris_microtime_delay				dq	102	; 6 klatek
taris_microtime_softdrop			dq	34	; 2 klatki

taris_limit					dq	(taris_bricks_end - taris_bricks) / STATIC_QWORD_SIZE_byte
taris_limit_model				dq	STATIC_QWORD_SIZE_byte / STATIC_WORD_SIZE_byte
taris_seed					dd	0x681560BA

taris_speed_table:				dw	819, 734, 649, 563, 478, 393, 307, 222, 137, 102, 85, 85, 85, 68, 68, 68, 51, 51, 51, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 17

taris_level_current				dd	STATIC_EMPTY
taris_lines					dd	STATIC_EMPTY
taris_points_total				dd	STATIC_EMPTY
taris_points_table:				dd	STATIC_EMPTY
						dd	0x28
						dd	0x64
						dd	0x012C
						dd	0x04B0

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
;===============================================================================
taris_window:					dw	STATIC_EMPTY	; pozycja na osi X
						dw	STATIC_EMPTY	; pozycja na osi Y
						dw	TARIS_WINDOW_WIDTH_pixel	; szerokość okna
						dw	TARIS_WINDOW_HEIGHT_pixel + LIBRARY_BOSU_HEADER_HEIGHT_pixel	; wysokość okna
						dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna (uzupełnia Bosu)
.extra:						dd	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach (uzupełnia Bosu)
						dw	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_header | LIBRARY_BOSU_WINDOW_FLAG_border | LIBRARY_BOSU_WINDOW_FLAG_BUTTON_close
						dq	STATIC_EMPTY	; identyfikator okna (uzupełnia Bosu)
						db	5
						db	"Taris                          "	; wypełnij do 31 Bajtów znakami STATIC_SCANCODE_SPACE
						dq	STATIC_EMPTY	; szerokość okna w Bajtach (uzupełnia Bosu)
.elements:					;-------------------------------
.element_button_close:				; element "window close"
						;-------------------------------
						db	LIBRARY_BOSU_ELEMENT_TYPE_button_close
						dw	.element_button_close_end - .element_button_close
						dq	taris.close
.element_button_close_end:			;-------------------------------
						; element "label points"
						;-------------------------------
.element_label_points:				db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_points_end - .element_label_points
						dw	0
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	TARIS_WINDOW_WIDTH_pixel / 3
						dw	LIBRARY_FONT_HEIGHT_pixel
						dq	STATIC_EMPTY
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_center	; domyślne wyrównanie tekstu
						db	6
						db	"Points"
.element_label_points_end:			;-------------------------------
						; element "label points value"
						;-------------------------------
.element_label_points_value:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_points_value_end - .element_label_points_value
						dw	0
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + LIBRARY_FONT_HEIGHT_pixel
						dw	TARIS_WINDOW_WIDTH_pixel / 3
						dw	LIBRARY_FONT_HEIGHT_pixel
						dq	STATIC_EMPTY
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_center	; domyślne wyrównanie tekstu
.element_label_points_value_length		db	1
.element_label_points_value_string		db	"0"
						db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, STATIC_EMPTY
.element_label_points_value_end:		;-------------------------------
						; element "label level"
						;-------------------------------
.element_label_level:				db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_level_end - .element_label_level
						dw	TARIS_WINDOW_WIDTH_pixel / 3
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	TARIS_WINDOW_WIDTH_pixel / 3
						dw	LIBRARY_FONT_HEIGHT_pixel
						dq	STATIC_EMPTY
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_center	; domyślne wyrównanie tekstu
						db	5
						db	"Level"
.element_label_level_end:			;-------------------------------
						; element "label level value"
						;-------------------------------
.element_label_level_value:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_level_value_end - .element_label_level_value
						dw	TARIS_WINDOW_WIDTH_pixel / 3
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + LIBRARY_FONT_HEIGHT_pixel
						dw	TARIS_WINDOW_WIDTH_pixel / 3
						dw	LIBRARY_FONT_HEIGHT_pixel
						dq	STATIC_EMPTY
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_center	; domyślne wyrównanie tekstu
.element_label_level_value_length		db	1
.element_label_level_value_string		db	"0"
						db	0x00, 0x00
.element_label_level_value_end:			;-------------------------------
						; element "label lines"
						;-------------------------------
.element_label_lines:				db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_lines_end - .element_label_lines
						dw	TARIS_WINDOW_WIDTH_pixel - (TARIS_WINDOW_WIDTH_pixel / 3)
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	TARIS_WINDOW_WIDTH_pixel / 3
						dw	LIBRARY_FONT_HEIGHT_pixel
						dq	STATIC_EMPTY
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_center	; domyślne wyrównanie tekstu
						db	5
						db	"Lines"
.element_label_lines_end:			;-------------------------------
						; element "label lines value"
						;-------------------------------
.element_label_lines_value:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_lines_value_end - .element_label_lines_value
						dw	TARIS_WINDOW_WIDTH_pixel - (TARIS_WINDOW_WIDTH_pixel / 3)
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + LIBRARY_FONT_HEIGHT_pixel
						dw	TARIS_WINDOW_WIDTH_pixel / 3
						dw	LIBRARY_FONT_HEIGHT_pixel
						dq	STATIC_EMPTY
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_center	; domyślne wyrównanie tekstu
.element_label_lines_value_length		db	1
.element_label_lines_value_string		db	"0"
						db	0x00, 0x00
.element_label_lines_value_end:			;-------------------------------
						; element "label game over"
						;-------------------------------
.element_label_game_over:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_game_over_end - .element_label_game_over
						dw	0
						dw	(TARIS_PLAYGROUND_HEIGHT_pixel >> STATIC_DIVIDE_BY_2_shift) + (LIBRARY_FONT_HEIGHT_pixel << STATIC_MULTIPLE_BY_2_shift)
						dw	TARIS_WINDOW_WIDTH_pixel
						dw	LIBRARY_FONT_HEIGHT_pixel + (LIBRARY_FONT_HEIGHT_pixel >> STATIC_DIVIDE_BY_2_shift)
						dq	STATIC_EMPTY
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_center	; domyślne wyrównanie tekstu
						db	13
						db	"~ Game Over ~"
.element_label_game_over_end:			;-------------------------------
						; element "playground"
						;-------------------------------
.element_playground:				db	LIBRARY_BOSU_ELEMENT_TYPE_draw
						dw	.element_playground_end - .element_playground
						dw	0	; pozycja na osi X względem przestrzeni danych okna
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + (LIBRARY_FONT_HEIGHT_pixel << STATIC_MULTIPLE_BY_2_shift)
						dw	TARIS_PLAYGROUND_WIDTH_pixel
						dw	TARIS_PLAYGROUND_HEIGHT_pixel
						dq	STATIC_EMPTY	; brak obsługi wyjątku
						dq	STATIC_EMPTY	; adres przestrzeni elementu (uzupełnia Bosu)
.element_playground_end:			;-------------------------------
						; koniec elementów okna
						;-------------------------------
						db	STATIC_EMPTY
taris_window_end:

;===============================================================================
align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
taris_bricks:					dq	0010011000100000000001110010000000100011001000000010011100000000b	; T
						dq	0010001001100000000001110001000000110010001000000100011100000000b	; J
						dq	0010011001000000011000110000000000100110010000000110001100000000b	; Z
						dq	0000001100110000000000110011000000000011001100000000001100110000b	; O
						dq	0100011000100000001101100000000001000110001000000011011000000000b	; S
						dq	0110001000100000000001110100000000100010001100000001011100000000b	; L
						dq	0010001000100010000011110000000000100010001000100000111100000000b	; I
taris_bricks_end:

taris_colors:					dd	0x00EE0000	; T
						dd	0x00EEB900	; J
						dd	0x0027EE00	; Z
						dd	0x0000EE70	; O
						dd	0x000070EE	; S
						dd	0x002700EE	; L
						dd	0x00EE00b9	; I

taris_brick_position_x				dq	STATIC_EMPTY
taris_brick_position_y				dq	STATIC_EMPTY

taris_playground_colors_table			dq	STATIC_EMPTY

;===============================================================================
taris_brick_platform_clean			dw	TARIS_PLAYGROUND_EMPTY_bits
taris_brick_platform:
	TIMES TARIS_PLAYGROUND_HEIGHT_brick	dw	STATIC_EMPTY
taris_brick_platform_end:			dw	STATIC_MAX_unsigned

;===============================================================================
align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
taris_rgl_properties:				dw	TARIS_PLAYGROUND_WIDTH_pixel	; szerokość w pikselach
						dw	TARIS_PLAYGROUND_HEIGHT_pixel	; wysokość w pikselach
						dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych
						dq	(TARIS_PLAYGROUND_WIDTH_pixel * TARIS_PLAYGROUND_HEIGHT_pixel) << KERNEL_VIDEO_DEPTH_shift	; rozmiar przestrzeni w Bajtach
						dq	(TARIS_WINDOW_WIDTH_pixel + (LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift)) << KERNEL_VIDEO_DEPTH_shift	; scanline w Bajtach
						dq	STATIC_EMPTY	; wskaźnik do przestrzeni tymczasowej (uzupełnia RGL)
						dd	STATIC_COLOR_BACKGROUND_default	; domyślny kolor tła

;===============================================================================
taris_rgl_square:				dw	0
						dw	0
						dw	TARIS_BRICK_WIDTH_pixel
						dw	TARIS_BRICK_HEIGHT_pixel
						dd	STATIC_COLOR_red_light
