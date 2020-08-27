;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

align	STATIC_QWORD_SIZE_byte,	db	STATIC_NOTHING

library_bosu_element_entry:
	.null:			dq	STATIC_EMPTY
	.header:		dq	library_bosu_element_header
	.label:			dq	library_bosu_element_label
	.draw:			dq	STATIC_EMPTY
	.chain:			dq	STATIC_EMPTY
	.button:		dq	library_bosu_element_button
	.taskbar		dq	library_bosu_element_taskbar
