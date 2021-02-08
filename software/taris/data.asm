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

taris_microtime					dd	1024	; 1024 == 1 sekunda

taris_limit					dq	(taris_bricks_end - taris_bricks) / STATIC_QWORD_SIZE_byte
taris_limit_model				dq	STATIC_QWORD_SIZE_byte / STATIC_WORD_SIZE_byte
taris_seed					dd	0x681560BA

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
;===============================================================================
taris_window					dw	STATIC_EMPTY	; pozycja na osi X
						dw	STATIC_EMPTY	; pozycja na osi Y
						dw	TARIS_WINDOW_WIDTH_pixel	; szerokość okna
						dw	TARIS_WINDOW_HEIGHT_pixel	; wysokość okna
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
						; element "playground"
						;-------------------------------
.element_playground:				db	LIBRARY_BOSU_ELEMENT_TYPE_draw
						dw	.element_playground_end - .element_playground
						dw	0	; pozycja na osi X względem przestrzeni danych okna
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	TARIS_PLAYGROUND_WIDTH_pixel
						dw	TARIS_WINDOW_HEIGHT_pixel
						dq	STATIC_EMPTY	; brak obsługi wyjątku
						dq	STATIC_EMPTY	; adres przestrzeni elementu (uzupełnia Bosu)
.element_playground_end:			;-------------------------------
						; koniec elementów okna
						;-------------------------------
						db	STATIC_EMPTY
taris_window_end:

;===============================================================================
align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
taris_bricks					dq	0x0720232027002620
						dq	0x6220074022301700
						dq	0x2310360023103600
						dq	0x6600660066006600
						dq	0x1320630013206300
						dq	0x0710226047003220
						dq	0x0F0022220F002222
taris_bricks_end:

taris_brick_position_x				dq	STATIC_EMPTY
taris_brick_position_y				dq	STATIC_EMPTY

;===============================================================================
taris_brick_platform:
	TIMES TARIS_PLAYGROUND_HEIGHT_brick	dw	0000100000000001b
						dw	0000111111111111b

;===============================================================================
align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
taris_rgl_properties				dw	TARIS_PLAYGROUND_WIDTH_pixel	; szerokość w pikselach
						dw	TARIS_PLAYGROUND_HEIGHT_pixel	; wysokość w pikselach
						dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych
						dq	(TARIS_PLAYGROUND_WIDTH_pixel * TARIS_PLAYGROUND_HEIGHT_pixel) << KERNEL_VIDEO_DEPTH_shift	; rozmiar przestrzeni w Bajtach
						dq	(TARIS_PLAYGROUND_WIDTH_pixel + (LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift)) << KERNEL_VIDEO_DEPTH_shift	; scanline w Bajtach
						dd	STATIC_COLOR_BACKGROUND_default	; domyślny kolor tła

;===============================================================================
taris_rgl_square:				dw	(TARIS_PLAYGROUND_WIDTH_pixel / 2) - (TARIS_BRICK_WIDTH_pixel / 2)
						dw	((TARIS_PLAYGROUND_HEIGHT_pixel / 2) - (TARIS_BRICK_HEIGHT_pixel / 2)) + LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	TARIS_BRICK_WIDTH_pixel
						dw	TARIS_BRICK_HEIGHT_pixel
						dd	STATIC_COLOR_red_light
