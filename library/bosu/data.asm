;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

align	STATIC_QWORD_SIZE_byte,	db	STATIC_NOTHING

library_bosu_element_entry:
	.null:			dq	STATIC_EMPTY				; 0x00
	.header:		dq	library_bosu_element_header		; 0x01
	.label:			dq	library_bosu_element_label		; 0x02
	.draw:			dq	STATIC_EMPTY				; 0x03
	.chain:			dq	STATIC_EMPTY				; 0x04
	.button:		dq	library_bosu_element_button		; 0x05
	.taskbar:		dq	library_bosu_element_taskbar		; 0x06
	.button_close:		dq	library_bosu_element_button_close	; 0x07
	.button_minimize:	dq	library_bosu_element_button_minimize	; 0x08
	.buttom_maximize:	dq	library_bosu_element_button_maximize	; 0x09
