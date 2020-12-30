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
						; element "window close"
						;-------------------------------
.element_button_close:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button_close
						dq	.element_button_close_end - .element_button_close
						dq	soler.close
.element_button_close_end:			;-------------------------------
						; element "label"
						;-------------------------------
.element_label:					dd	LIBRARY_BOSU_ELEMENT_TYPE_label
						dq	.element_label_end - .element_label
						dq	1
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dq	64 + 3
						dq	16
						dq	STATIC_EMPTY
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_right
						db	1
						db	"0"
.element_label_end:				;-------------------------------
						; element "button C"
						;-------------------------------
.element_button_C:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_C_end - .element_button_C	; size
						dq	1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"C"						; name
.element_button_C_end:				;-------------------------------
						; element "button 7"
						;-------------------------------
.element_button_7:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_7_end - .element_button_7	; size
						dq	1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"7"						; name
.element_button_7_end:				;-------------------------------
						; element "button 4"
						;-------------------------------
.element_button_4:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_4_end - .element_button_4	; size
						dq	1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"4"						; name
.element_button_4_end:				;-------------------------------
						; element "button 1"
						;-------------------------------
.element_button_1:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_1_end - .element_button_1	; size
						dq	1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1 + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"1"						; name
.element_button_1_end:				;-------------------------------
						; element "button 0"
						;-------------------------------
.element_button_0:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_0_end - .element_button_0	; size
						dq	1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1 + 16 + 1 + 16 + 1 + 16 + 1					; y
						dq	32 + 1						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"0"						; name
.element_button_0_end:				;-------------------------------
						; element "button DIVIDE"
						;-------------------------------
.element_button_DIVIDE:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_DIVIDE_end - .element_button_DIVIDE	; size
						dq	1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"/"						; name
.element_button_DIVIDE_end:			;-------------------------------
						; element "button 8"
						;-------------------------------
.element_button_8:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_8_end - .element_button_8	; size
						dq	1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"8"						; name
.element_button_8_end:				;-------------------------------
						; element "button 5"
						;-------------------------------
.element_button_5:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_5_end - .element_button_5	; size
						dq	1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"5"						; name
.element_button_5_end:				;-------------------------------
						; element "button 2"
						;-------------------------------
.element_button_2:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_2_end - .element_button_2	; size
						dq	1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1 + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"2"						; name
.element_button_2_end:				;-------------------------------
						; element "button MULTIPLY"
						;-------------------------------
.element_button_MULTIPLY:			dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_MULTIPLY_end - .element_button_MULTIPLY	; size
						dq	1 + 16 + 1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"*"						; name
.element_button_MULTIPLY_end:			;-------------------------------
						; element "button 9"
						;-------------------------------
.element_button_9:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_9_end - .element_button_9	; size
						dq	1 + 16 + 1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"9"						; name
.element_button_9_end:				;-------------------------------
						; element "button 6"
						;-------------------------------
.element_button_6:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_6_end - .element_button_6	; size
						dq	1 + 16 + 1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"6"						; name
.element_button_6_end:				;-------------------------------
						; element "button 3"
						;-------------------------------
.element_button_3:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_3_end - .element_button_3	; size
						dq	1 + 16 + 1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1 + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"3"						; name
.element_button_3_end:				;-------------------------------
						; element "button DOT"
						;-------------------------------
.element_button_DOT:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_DOT_end - .element_button_DOT	; size
						dq	1 + 16 + 1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1 + 16 + 1 + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"."						; name
.element_button_DOT_end:			;-------------------------------
						; element "button SUB"
						;-------------------------------
.element_button_SUB:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_SUB_end - .element_button_SUB	; size
						dq	1 + 16 + 1 + 16 + 1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1					; y
						dq	16						; width
						dq	16						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"-"						; name
.element_button_SUB_end:			;-------------------------------
						; element "button ADD"
						;-------------------------------
.element_button_ADD:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_ADD_end - .element_button_ADD	; size
						dq	1 + 16 + 1 + 16 + 1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	32 + 1						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"+"						; name
.element_button_ADD_end:			;-------------------------------
						; element "button RESULT"
						;-------------------------------
.element_button_RESULT:				dd	LIBRARY_BOSU_ELEMENT_TYPE_button		; type
						dq	.element_button_RESULT_end - .element_button_RESULT	; size
						dq	1 + 16 + 1 + 16 + 1 + 16 + 1					; x
						dq	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 16 + 1 + 16 + 1 + 16 + 1 + 16 + 1					; y
						dq	16						; width
						dq	32 + 1						; height
						dq	soler_button_7					; wyjątek
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1						; length
						db	"="						; name
.element_button_RESULT_end:			;-------------------------------
						; koniec elementów okna
						;-------------------------------
						dd	STATIC_EMPTY
soler_window_end:
