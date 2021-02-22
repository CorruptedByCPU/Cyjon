;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
soler_fpu_float_result				dq	STATIC_EMPTY
soler_fpu_precision				dq	STATIC_EMPTY
soler_fpu_precision_value			dq	10	; jedno miejsce po przecinku
soler_fpu_control				dw	0

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
soler_fpu_integer				dq	0
soler_fpu_fraction				dq	0

soler_value_exec				db	STATIC_EMPTY
soler_value_first				dq	0.0
soler_value_second				dq	0.0

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
						dd	STATIC_EMPTY	; szerokość okna w Bajtach (uzupełnia Bosu)
						dd	STATIC_COLOR_black	; kolor tła okna
.elements:					;-------------------------------
						; element "window close"
						;-------------------------------
.element_button_close:				db	LIBRARY_BOSU_ELEMENT_TYPE_button_close
						dw	.element_button_close_end - .element_button_close
						dq	soler.close
.element_button_close_end:			;-------------------------------
						; element "label operation"
						;-------------------------------
.element_label_operation:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_operation_end - .element_label_operation
						dw	SOLER_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	SOLER_INPUT_OPERATION_WIDTH_pixel
						dw	SOLER_INPUT_HEIGHT_pixel
						dq	STATIC_EMPTY
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_right
.element_label_operation_length:		db	1
.element_label_operation_string:		db	STATIC_SCANCODE_SPACE
times	SOLER_INPUT_OPERATION_WIDTH_char - 0x01	db	STATIC_EMPTY
.element_label_operation_end:			;-------------------------------
						; element "label value"
						;-------------------------------
.element_label_value:				db	LIBRARY_BOSU_ELEMENT_TYPE_label
						dw	.element_label_value_end - .element_label_value
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_INPUT_OPERATION_WIDTH_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	SOLER_INPUT_VALUE_WIDTH_pixel
						dw	SOLER_INPUT_HEIGHT_pixel
						dq	STATIC_EMPTY
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_right
.element_label_value_length:			db	1
.element_label_value_string:			db	"0"
times	SOLER_INPUT_VALUE_WIDTH_char - 0x01	db	STATIC_EMPTY
.element_label_value_end:			;-------------------------------
						; element "button C"
						;-------------------------------
.element_button_C:				db	LIBRARY_BOSU_ELEMENT_TYPE_button	; typ
						dw	.element_button_C_end - .element_button_C	; rozmiar elementu
						dw	SOLER_WINDOW_PADDING_pixel	; x
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel	; y
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel	; szerokość
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel	; wysokość
						dq	STATIC_SCANCODE_ESCAPE	; wartość przechowywana przez element
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1	; ilość znaków reprezentujących nazwę przycisku
						db	"C"	; ciąg znaków reprezentujący nazwę przycisku
.element_button_C_end:				;-------------------------------
						; element "button 7"
						;-------------------------------
.element_button_7:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_7_end - .element_button_7
						dw	SOLER_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_7
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"7"
.element_button_7_end:				;-------------------------------
						; element "button 4"
						;-------------------------------
.element_button_4:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_4_end - .element_button_4
						dw	SOLER_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_4
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"4"
.element_button_4_end:				;-------------------------------
						; element "button 1"
						;-------------------------------
.element_button_1:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_1_end - .element_button_1
						dw	SOLER_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_1
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"1"
.element_button_1_end:				;-------------------------------
						; element "button 0"
						;-------------------------------
.element_button_0:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_0_end - .element_button_0
						dw	SOLER_WINDOW_PADDING_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x04
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_0
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"0"
.element_button_0_end:				;-------------------------------
						; element "button DIVIDE"
						;-------------------------------
.element_button_DIVIDE:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_DIVIDE_end - .element_button_DIVIDE
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	"/"
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"/"
.element_button_DIVIDE_end:			;-------------------------------
						; element "button 8"
						;-------------------------------
.element_button_8:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_8_end - .element_button_8
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_8
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"8"
.element_button_8_end:				;-------------------------------
						; element "button 5"
						;-------------------------------
.element_button_5:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_5_end - .element_button_5
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_5
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"5"
.element_button_5_end:				;-------------------------------
						; element "button 2"
						;-------------------------------
.element_button_2:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_2_end - .element_button_2
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_2
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"2"
.element_button_2_end:				;-------------------------------
						; element "button MULTIPLY"
						;-------------------------------
.element_button_MULTIPLY:			db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_MULTIPLY_end - .element_button_MULTIPLY
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	"*"
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"*"
.element_button_MULTIPLY_end:			;-------------------------------
						; element "button 9"
						;-------------------------------
.element_button_9:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_9_end - .element_button_9
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_9
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"9"
.element_button_9_end:				;-------------------------------
						; element "button 6"
						;-------------------------------
.element_button_6:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_6_end - .element_button_6
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_6
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"6"
.element_button_6_end:				;-------------------------------
						; element "button 3"
						;-------------------------------
.element_button_3:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_3_end - .element_button_3
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_DIGIT_3
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"3"
.element_button_3_end:				;-------------------------------
						; element "button DOT"
						;-------------------------------
.element_button_DOT:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_DOT_end - .element_button_DOT
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x02
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x04
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	","
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	","
.element_button_DOT_end:			;-------------------------------
						; element "button SUB"
						;-------------------------------
.element_button_SUB:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_SUB_end - .element_button_SUB
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dq	STATIC_SCANCODE_MINUS
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"-"
.element_button_SUB_end:			;-------------------------------
						; element "button ADD"
						;-------------------------------
.element_button_ADD:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_ADD_end - .element_button_ADD
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dq	"+"
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"+"
.element_button_ADD_end:			;-------------------------------
						; element "button RESULT"
						;-------------------------------
.element_button_RESULT:				db	LIBRARY_BOSU_ELEMENT_TYPE_button
						dw	.element_button_RESULT_end - .element_button_RESULT
						dw	SOLER_WINDOW_PADDING_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + SOLER_INPUT_HEIGHT_pixel + SOLER_WINDOW_ELEMENT_MARGIN_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel * 0x03
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel
						dw	SOLER_WINDOW_ELEMENT_SIZE_pixel + SOLER_WINDOW_ELEMENT_AREA_pixel
						dq	STATIC_SCANCODE_RETURN
						dd	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
						dd	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
						db	LIBRARY_BOSU_ELEMENT_BUTTON_FLAG_ALIGN_default
						db	1
						db	"="
.element_button_RESULT_end:			;-------------------------------
						; koniec elementów okna
						;-------------------------------
						db	STATIC_EMPTY
soler_window_end:
