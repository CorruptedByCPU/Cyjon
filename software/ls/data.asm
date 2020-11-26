;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

ls_string_init			db	STATIC_SEQUENCE_CURSOR_DISABLE
ls_string_init_end:

ls_path_local			db	"."
ls_path_local_end:

ls_string_separator		db	STATIC_SCANCODE_SPACE
ls_string_separator_end:

ls_string_color_file		db	STATIC_SEQUENCE_COLOR_DEFAULT
ls_string_color_file_end:
ls_string_color_directory	db	STATIC_SEQUENCE_COLOR_BLUE_LIGHT
ls_string_color_directory_end:

ls_string_error_not_found	db	"File not found."
ls_string_error_not_found_end:
