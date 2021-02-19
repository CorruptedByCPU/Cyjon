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

taris_microtime					dq	1024	; 1024 == 1 sekunda

taris_limit					dq	(taris_bricks_end - taris_bricks) / STATIC_QWORD_SIZE_byte
taris_limit_model				dq	STATIC_QWORD_SIZE_byte / STATIC_WORD_SIZE_byte
taris_seed					dd	0x681560BA

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
;===============================================================================
taris_window					dw	STATIC_EMPTY	; pozycja na osi X
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
						; element "playground"
						;-------------------------------
.element_playground:				db	LIBRARY_BOSU_ELEMENT_TYPE_draw
						dw	.element_playground_end - .element_playground
						dw	0	; pozycja na osi X względem przestrzeni danych okna
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
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

taris_colors					dd	0x00ff0000	; T
						dd	0x00ffdb00	; J
						dd	0x0049ff00	; Z
						dd	0x0000ff92	; O
						dd	0x000092ff	; S
						dd	0x004900ff	; L
						dd	0x00ff00db	; I


taris_brick_position_x				dq	STATIC_EMPTY
taris_brick_position_y				dq	STATIC_EMPTY

;===============================================================================
taris_brick_platform_clean			dw	TARIS_PLAYGROUND_EMPTY_bits
taris_brick_platform:
	TIMES TARIS_PLAYGROUND_HEIGHT_brick	dw	STATIC_EMPTY
taris_brick_platform_end:			dw	STATIC_MAX_unsigned

;===============================================================================
align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
taris_rgl_properties				dw	TARIS_PLAYGROUND_WIDTH_pixel	; szerokość w pikselach
						dw	TARIS_PLAYGROUND_HEIGHT_pixel	; wysokość w pikselach
						dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych
						dq	(TARIS_PLAYGROUND_WIDTH_pixel * TARIS_PLAYGROUND_HEIGHT_pixel) << KERNEL_VIDEO_DEPTH_shift	; rozmiar przestrzeni w Bajtach
						dq	(TARIS_PLAYGROUND_WIDTH_pixel + (LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift)) << KERNEL_VIDEO_DEPTH_shift	; scanline w Bajtach
						dq	STATIC_EMPTY	; wskaźnik do przestrzeni tymczasowej (uzupełnia RGL)
						dd	STATIC_COLOR_BACKGROUND_default	; domyślny kolor tła

;===============================================================================
taris_rgl_square:				dw	0
						dw	0
						dw	TARIS_BRICK_WIDTH_pixel
						dw	TARIS_BRICK_HEIGHT_pixel
						dd	STATIC_COLOR_red_light
