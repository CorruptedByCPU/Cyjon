;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

LIBRARY_BASE_address			equ	0x0000700000000000

struc	LIBRARY_STRUCTURE_ENTRY
	;-----------------------------------------------------------------------
	.bit_find			resb	8
	;-----------------------------------------------------------------------
	.bosu				resb	8
	.bosu_element			resb	8
	.bosu_element_chain		resb	8
	.bosu_element_label		resb	8
	.bosu_elements_specification	resb	8
	.bosu_event			resb	8
	.bosu_header_set		resb	8
	;-----------------------------------------------------------------------
	.bresenham			resb	8
	;-----------------------------------------------------------------------
	.color_alpha			resb	8
	.color_alpha_invert		resb	8
	;-----------------------------------------------------------------------
	.font_matrix			resb	8
	;-----------------------------------------------------------------------
	.input				resb	8
	;-----------------------------------------------------------------------
	.integer_to_string		resb	8
	;-----------------------------------------------------------------------
	.page_align_up			resb	8
	.page_from_size			resb	8
	;-----------------------------------------------------------------------
	.rgl				resb	8
	.rgl_clear			resb	8
	.rgl_flush			resb	8
	.rgl_square			resb	8
	;-----------------------------------------------------------------------
	.string_compare			resb	8
	.string_cut			resb	8
	.string_digits			resb	8
	.string_to_float		resb	8
	.string_to_integer		resb	8
	.string_trim			resb	8
	.string_word_next		resb	8
	;-----------------------------------------------------------------------
	.terminal			resb	8
	.terminal_char			resb	8
	.terminal_clear			resb	8
	.terminal_cursor_disable	resb	8
	.terminal_cursor_enable		resb	8
	.terminal_cursor_set		resb	8
	.terminal_cursor_switch		resb	8
	.terminal_empty_char		resb	8
	.terminal_empty_line		resb	8
	.terminal_matrix		resb	8
	.terminal_number		resb	8
	.terminal_scroll		resb	8
	.terminal_scroll_down		resb	8
	.terminal_scroll_up		resb	8
	.terminal_string		resb	8
	;-----------------------------------------------------------------------
	.value_to_size			resb	8
	;-----------------------------------------------------------------------
	.xorshift32			resb	8
	;-----------------------------------------------------------------------
endstruc
