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

taris_limit					dq	(taris_bricks_end - taris_bricks) / STATIC_QWORD_SIZE_byte
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
						dq	STATIC_EMPTY	; wskaźnik przestrzeni danych (uzupełnia Bosu)
.element_playground_end:			;-------------------------------
						; koniec elementów okna
						;-------------------------------
						db	STATIC_EMPTY
taris_window_end:

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
taris_bricks					dq	0x0270023200720262
						dq	0x0226047003220071
						dq	0x0063013200630132
						dq	0x0066006600660066
						dq	0x0036023100360231
						dq	0x0223007406220170
						dq	0x222200F0222200F0
taris_bricks_end:

taris_brick_position_x				dq	STATIC_EMPTY
taris_brick_position_y				dq	STATIC_EMPTY

taris_brick_platform:
	TIMES TARIS_PLAYGROUND_HEIGHT_brick	dw	0000000000000000b	; najmłodsze 10 bitów
