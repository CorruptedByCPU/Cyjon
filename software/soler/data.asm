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
soler_window:					dw	STATIC_EMPTY	; pozycja na osi X
						dw	STATIC_EMPTY	; pozycja na osi Y
						dw	SOLER_WINDOW_WIDTH_pixel	; szerokość okna
						dw	SOLER_WINDOW_HEIGHT_pixel	; wysokość okna
						dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych okna (uzupełnia Bosu)
.extra:						dd	STATIC_EMPTY	; rozmiar przestrzeni danych okna w Bajtach (uzupełnia Bosu)
						dw	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_header | LIBRARY_BOSU_WINDOW_FLAG_border | LIBRARY_BOSU_WINDOW_FLAG_BUTTON_close
						dq	STATIC_EMPTY	; identyfikator okna (uzupełnia Bosu)
						db	5
						db	"Soler                          "	; wypełnij do 31 Bajtów znakami STATIC_SCANCODE_SPACE
						dq	STATIC_EMPTY	; szerokość okna w Bajtach (uzupełnia Bosu)
.elements:					;-------------------------------
						; element "window close"
						;-------------------------------
.element_button_close:				db	LIBRARY_BOSU_ELEMENT_TYPE_button_close
						dw	.element_button_close_end - .element_button_close
						dq	soler.close
.element_button_close_end:			;-------------------------------
						; element "label"
						;-------------------------------
.element_label:					db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_end - .element_label
						dw	SOLER_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	SOLER_INPUT_WIDTH_pixel
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel
						dq	STATIC_EMPTY
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_right
						db	1
						db	"0"
	times	SOLER_INPUT_SIZE_char - 0x01	db	STATIC_EMPTY
.element_label_end:				;-------------------------------
						; element "button C"
						;-------------------------------
.element_button_C:				db	LIBRARY_BOSU_ELEMENT_TYPE_button	; type
						dw	.element_button_C_end - .element_button_C	; size
						dw	SOLER_WINDOW_PADDING_pixel	; x
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel	; y
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7	; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1	; length
						db	"C"	; name
.element_button_C_end:				;-------------------------------
						; element "button 7"
						;-------------------------------
.element_button_7:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_7_end - .element_button_7
						dw	SOLER_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"7"						; name
.element_button_7_end:				;-------------------------------
						; element "button 4"
						;-------------------------------
.element_button_4:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_4_end - .element_button_4	; size
						dw	SOLER_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"4"						; name
.element_button_4_end:				;-------------------------------
						; element "button 1"
						;-------------------------------
.element_button_1:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_1_end - .element_button_1	; size
						dw	SOLER_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x04
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"1"						; name
.element_button_1_end:				;-------------------------------
						; element "button 0"
						;-------------------------------
.element_button_0:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_0_end - .element_button_0	; size
						dw	SOLER_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x05
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"0"						; name
.element_button_0_end:				;-------------------------------
						; element "button DIVIDE"
						;-------------------------------
.element_button_DIVIDE:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_DIVIDE_end - .element_button_DIVIDE	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"/"						; name
.element_button_DIVIDE_end:			;-------------------------------
						; element "button 8"
						;-------------------------------
.element_button_8:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_8_end - .element_button_8	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"8"						; name
.element_button_8_end:				;-------------------------------
						; element "button 5"
						;-------------------------------
.element_button_5:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_5_end - .element_button_5	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"5"						; name
.element_button_5_end:				;-------------------------------
						; element "button 2"
						;-------------------------------
.element_button_2:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_2_end - .element_button_2	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x04
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"2"						; name
.element_button_2_end:				;-------------------------------
						; element "button MULTIPLY"
						;-------------------------------
.element_button_MULTIPLY:			db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_MULTIPLY_end - .element_button_MULTIPLY	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"*"						; name
.element_button_MULTIPLY_end:			;-------------------------------
						; element "button 9"
						;-------------------------------
.element_button_9:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_9_end - .element_button_9	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"9"						; name
.element_button_9_end:				;-------------------------------
						; element "button 6"
						;-------------------------------
.element_button_6:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_6_end - .element_button_6	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"6"						; name
.element_button_6_end:				;-------------------------------
						; element "button 3"
						;-------------------------------
.element_button_3:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_3_end - .element_button_3	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x04
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"3"						; name
.element_button_3_end:				;-------------------------------
						; element "button DOT"
						;-------------------------------
.element_button_DOT:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_DOT_end - .element_button_DOT	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x05
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"."						; name
.element_button_DOT_end:			;-------------------------------
						; element "button SUB"
						;-------------------------------
.element_button_SUB:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_SUB_end - .element_button_SUB	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel	; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"-"						; name
.element_button_SUB_end:			;-------------------------------
						; element "button ADD"
						;-------------------------------
.element_button_ADD:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_ADD_end - .element_button_ADD	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel						; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"+"						; name
.element_button_ADD_end:			;-------------------------------
						; element "button RESULT"
						;-------------------------------
.element_button_RESULT:				db	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dw	.element_button_RESULT_end - .element_button_RESULT	; size
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x04
						dw	SOLER_WINDOW_ELEMENT_WIDTH_pixel						; width
						dw	SOLER_WINDOW_ELEMENT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel	; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"="						; name
.element_button_RESULT_end:			;-------------------------------
						; koniec elementów okna
						;-------------------------------
						db	STATIC_EMPTY
soler_window_end:
