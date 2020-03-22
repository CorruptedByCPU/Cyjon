;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

align	STATIC_QWORD_SIZE_byte,	db	STATIC_NOTHING

library_bosu_element_entry:
	.null:			dq	STATIC_EMPTY
	.header:		dq	library_bosu_element_header
	.label:			dq	library_bosu_element_label
	.draw:			dq	STATIC_EMPTY
	.chain:			dq	library_bosu_element_chain
	.button:		dq	library_bosu_element_button
