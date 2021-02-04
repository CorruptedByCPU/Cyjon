;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"kernel/header.asm"
	;-----------------------------------------------------------------------

; 64 bitowy kod programu
[bits 64]

; adresowanie względne
[default rel]

; położenie kodu programu w pamięci logicznej
[org LIBRARY_BASE_address]

;===============================================================================
kernel_library:
	;-----------------------------------------------------------------------
	.bit_find			dq	library_bit_find
	;-----------------------------------------------------------------------
	.bosu				dq	library_bosu
	.bosu_element			dq	library_bosu_element
	.bosu_element_chain		dq	library_bosu_element_chain
	.bosu_element_label		dq	library_bosu_element_label
	.bosu_elements_specification	dq	library_bosu_elements_specification
	.bosu_event			dq	library_bosu_event
	.bosu_header_set		dq	library_bosu_header_set
	;-----------------------------------------------------------------------
	.bresenham			dq	library_bresenham
	;-----------------------------------------------------------------------
	.color_alpha			dq	library_color_alpha
	.color_alpha_invert		dq	library_color_alpha_invert
	;-----------------------------------------------------------------------
	.font_matrix			dq	library_font_matrix
	;-----------------------------------------------------------------------
	.input				dq	library_input
	;-----------------------------------------------------------------------
	.integer_to_string		dq	library_integer_to_string
	;-----------------------------------------------------------------------
	.page_align_up			dq	library_page_align_up
	.page_from_size			dq	library_page_from_size
	;-----------------------------------------------------------------------
	.string_compare			dq	library_string_compare
	.string_cut			dq	library_string_cut
	.string_digits			dq	library_string_digits
	.string_to_float		dq	library_string_to_float
	.string_to_integer		dq	library_string_to_integer
	.string_trim			dq	library_string_trim
	.string_word_next		dq	library_string_word_next
	;-----------------------------------------------------------------------
	.terminal			dq	library_terminal
	.terminal_char			dq	library_terminal_char
	.terminal_clear			dq	library_terminal_clear
	.terminal_cursor_disable	dq	library_terminal_cursor_disable
	.terminal_cursor_enable		dq	library_terminal_cursor_enable
	.terminal_cursor_set		dq	library_terminal_cursor_set
	.terminal_cursor_switch		dq	library_terminal_cursor_switch
	.terminal_empty_char		dq	library_terminal_empty_char
	.terminal_empty_line		dq	library_terminal_empty_line
	.terminal_matrix		dq	library_terminal_matrix
	.terminal_number		dq	library_terminal_number
	.terminal_scroll		dq	library_terminal_scroll
	.terminal_scroll_down		dq	library_terminal_scroll_down
	.terminal_scroll_up		dq	library_terminal_scroll_up
	.terminal_string		dq	library_terminal_string
	;-----------------------------------------------------------------------
	.value_to_size			dq	library_value_to_size
	;-----------------------------------------------------------------------
	.xorshift32			dq	library_xorshift32
	;-----------------------------------------------------------------------

;-------------------------------------------------------------------------------
%include	"kernel/library/bit.asm"
%include	"kernel/library/bosu.asm"
%include	"kernel/library/bresenham.asm"
%include	"kernel/library/color.asm"
%include	"kernel/library/font.asm"
%include	"kernel/library/input.asm"
%include	"kernel/library/integer_to_string.asm"
%include	"kernel/library/page_align_up.asm"
%include	"kernel/library/page_from_size.asm"
%include	"kernel/library/string_compare.asm"
%include	"kernel/library/string_cut.asm"
%include	"kernel/library/string_digits.asm"
%include	"kernel/library/string_to_float.asm"
%include	"kernel/library/string_to_integer.asm"
%include	"kernel/library/string_trim.asm"
%include	"kernel/library/string_word_next.asm"
%include	"kernel/library/terminal.asm"
%include	"kernel/library/value_to_size.asm"
%include	"kernel/library/xorshift32.asm"
;-------------------------------------------------------------------------------
