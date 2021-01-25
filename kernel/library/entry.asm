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
	%include	"config.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"
	%include	"kernel/macro/debug.asm"
	%include	"kernel/header/ipc.inc"
	%include	"kernel/header/wm.inc"
	%include	"kernel/header/service.inc"
	;-----------------------------------------------------------------------
	%include	"library/header.inc"
	;-----------------------------------------------------------------------

; 64 bitowy kod programu
[bits 64]

; adresowanie względne
[default rel]

; położenie kodu programu w pamięci logicznej
[org LIBRARY_ENTRY_base_address]

;===============================================================================
library_entry:
	; ;-----------------------------------------------------------------------
	; .bit_find			dq	library_bit_find
	; ;-----------------------------------------------------------------------
	; .bosu				dq	library_bosu
	; .bosu_header_set		dq	library_bosu_header_set
	; .bosu_clean			dq	library_bosu_clean
	; .bosu_border_correction		dq	library_bosu_border_correction
	; .bosu_close			dq	library_bosu_close
	; .bosu_element_button_close	dq	library_bosu_element_button_close
	; .bosu_element_button_minimize	dq	library_bosu_element_button_minimize
	; .bosu_element_button_maximize	dq	library_bosu_element_button_maximize
	; .bosu_elements_specification	dq	library_bosu_elements_specification
	; .bosu_elements			dq	library_bosu_elements
	; .bosu_element_taskbar		dq	library_bosu_element_taskbar
	; .bosu_element_chain		dq	library_bosu_element_chain
	; .bosu_header_update		dq	library_bosu_header_update
	; .bosu_string			dq	library_bosu_string
	; .bosu_char			dq	library_bosu_char
	; .bosu_element_button		dq	library_bosu_element_button
	; .bosu_element_drain		dq	library_bosu_element_drain
	; .bosu_element_label		dq	library_bosu_element_label
	; .bosu_element			dq	library_bosu_element
	; .bosu_element_subroutine	dq	library_bosu_element_subroutine
	; ;-----------------------------------------------------------------------
	; .bresenham			dq	library_bresenham
	; ;-----------------------------------------------------------------------
	; .color_alpha			dq	library_color_alpha
	; .color_alpha_invert		dq	library_color_alpha_invert
	; ;-----------------------------------------------------------------------
	; .font				dq	library_font_matrix
	; ;-----------------------------------------------------------------------
	; .input				dq	library_input
	; ;-----------------------------------------------------------------------
	; .integer_to_string		dq	library_integer_to_string
	; ;-----------------------------------------------------------------------
	; .page_align_up			dq	library_page_align_up
	; .page_from_size			dq	library_page_from_size
	; ;-----------------------------------------------------------------------
	; .string_compare			dq	library_string_compare
	; .string_cut			dq	library_string_cut
	; .string_digits			dq	library_string_digits
	; .string_to_float		dq	library_string_to_float
	; .string_to_integer		dq	library_string_to_integer
	; .string_trim			dq	library_string_trim
	; .string_word_next		dq	library_string_word_next
	; ;-----------------------------------------------------------------------
	; .terminal			dq	library_terminal
	; .terminal_clear			dq	library_terminal_clear
	; .terminal_cursor_disable	dq	library_terminal_cursor_disable
	; .terminal_cursor_enable		dq	library_terminal_cursor_enable
	; .terminal_cursor_switch		dq	library_terminal_cursor_switch
	; .terminal_cursor_set		dq	library_terminal_cursor_set
	; .terminal_matrix		dq	library_terminal_matrix
	; .library_terminal_empty_char	dq	library_terminal_empty_char
	; .library_terminal_char		dq	library_terminal_char
	; .library_terminal_scroll	dq	library_terminal_scroll
	; .library_terminal_scroll_down	dq	library_terminal_scroll_down
	; .library_terminal_scroll_up	dq	library_terminal_scroll_up
	; .library_terminal_empty_line	dq	library_terminal_empty_line
	; .library_terminal_string	dq	library_terminal_string
	; .library_terminal_number	dq	library_terminal_number
	; ;-----------------------------------------------------------------------
	; .value_to_size			dq	library_value_to_size
	; ;-----------------------------------------------------------------------
	; .xorshift32			dq	library_xorshift32
	; ;-----------------------------------------------------------------------

;-------------------------------------------------------------------------------
%include	"library/bit.asm"
%include	"library/bosu.asm"
%include	"library/bresenham.asm"
%include	"library/color.asm"
%include	"library/font.asm"
%include	"library/input.asm"
%include	"library/integer_to_string.asm"
%include	"library/page_align_up.asm"
%include	"library/page_from_size.asm"
%include	"library/string_compare.asm"
%include	"library/string_cut.asm"
%include	"library/string_digits.asm"
%include	"library/string_to_float.asm"
%include	"library/string_to_integer.asm"
%include	"library/string_trim.asm"
%include	"library/string_word_next.asm"
%include	"library/terminal.asm"
%include	"library/value_to_size.asm"
%include	"library/xorshift32.asm"
;-------------------------------------------------------------------------------
