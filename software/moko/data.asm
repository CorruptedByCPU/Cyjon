;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

align	STATIC_QWORD_SIZE_byte,			db	STATIC_EMPTY
moko_stream_meta:
	times	KERNEL_STREAM_META_SIZE_byte	db	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
moko_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY

moko_modified_semaphore				db	STATIC_FALSE
moko_status_semaphore				db	STATIC_FALSE

moko_cache_address				dq	STATIC_EMPTY
moko_cache_size_byte				dq	STATIC_EMPTY

moko_document_start_address			dq	STATIC_EMPTY
moko_document_end_address			dq	STATIC_EMPTY
moko_document_area_size				dq	MOKO_DOCUMENT_AREA_SIZE_default
moko_document_size				dq	STATIC_EMPTY
moko_document_line_index_last			dq	STATIC_EMPTY
moko_document_line_begin_last			dq	STATIC_EMPTY
moko_document_line_count			dq	STATIC_EMPTY
moko_document_show_from_line			dq	STATIC_EMPTY

moko_string_document_cursor			db	"^[t1;"
					.joint:
					.x:	dw	STATIC_EMPTY
					.y:	dw	STATIC_EMPTY
						db	"]"
moko_string_document_cursor_end:

moko_string_cursor_at_menu_and_clear_screen	db	STATIC_SEQUENCE_CLEAR, "^[t1;"
						dw	STATIC_EMPTY
						dw	STATIC_MAX_unsigned
						db	"]"
moko_string_cursor_at_menu_and_clear_screen_end:
moko_string_cursor_at_begin_of_line		db	STATIC_SCANCODE_RETURN
moko_string_cursor_at_begin_of_line_end:
moko_string_cursor_to_row_previous		db	STATIC_SEQUENCE_CURSOR_UP
moko_string_cursor_to_row_previous_end:
moko_string_cursor_to_row_next			db	STATIC_SEQUENCE_CURSOR_DOWN
moko_string_cursor_to_row_next_end:
moko_string_cursor_to_col_previous		db	STATIC_SEQUENCE_CURSOR_LEFT
moko_string_cursor_to_col_previous_end:
moko_string_cursor_to_col_next			db	STATIC_SEQUENCE_CURSOR_RIGHT
moko_string_cursor_to_col_next_end:

moko_string_close				db	"^[t1;"
						dw	STATIC_MAX_unsigned
						dw	STATIC_MAX_unsigned
						db	"]"
moko_string_close_end:

moko_string_cursor_save				db	STATIC_SEQUENCE_CURSOR_PUSH
moko_string_cursor_save_end:
moko_string_cursor_restore			db	STATIC_SEQUENCE_CURSOR_POP
moko_string_cursor_restore_end:

moko_string_line_clean_next			db	STATIC_SEQUENCE_CURSOR_DOWN
moko_string_line_clean				db	STATIC_SEQUENCE_CLEAR_LINE, STATIC_SEQUENCE_COLOR_DEFAULT
moko_string_line_clean_end:
moko_string_line_clean_next_end:

moko_string_menu				db	"^[c70]^x^[c07] Exit ^[c70]^r^[c07] Read ^[c70]^o^[c07] Write", STATIC_SEQUENCE_COLOR_DEFAULT
moko_string_menu_end:

moko_string_menu_read				db	STATIC_SCANCODE_RETURN, STATIC_SEQUENCE_CLEAR_LINE, STATIC_SEQUENCE_COLOR_WHITE, "File: "
moko_string_menu_read_end:

moko_string_menu_not_found			db	STATIC_SCANCODE_RETURN, STATIC_SEQUENCE_CLEAR_LINE, STATIC_SEQUENCE_COLOR_RED_LIGHT, "Text file not found.", STATIC_SEQUENCE_COLOR_DEFAULT
moko_string_menu_not_found_end:

moko_string_menu_overwrite			db	STATIC_SCANCODE_RETURN, STATIC_SEQUENCE_CLEAR_LINE, STATIC_SEQUENCE_COLOR_YELLOW, "File already exist, overwrite?", STATIC_SEQUENCE_COLOR_DEFAULT, STATIC_SEQUENCE_CURSOR_DISABLE
moko_string_menu_overwrite_end:

moko_string_menu_answer				db	STATIC_SEQUENCE_CLEAR_LINE, STATIC_SEQUENCE_CURSOR_POP, STATIC_SEQUENCE_CURSOR_ENABLE
moko_string_menu_answer_end:

moko_string_menu_failed_write			db	STATIC_SCANCODE_RETURN, STATIC_SEQUENCE_CLEAR_LINE, STATIC_SEQUENCE_COLOR_RED_LIGHT, "Cannot write to file.", STATIC_SEQUENCE_COLOR_DEFAULT
moko_string_menu_failed_write_end:

moko_string_modified				db	STATIC_SEQUENCE_CLEAR_LINE, STATIC_SEQUENCE_COLOR_GRAY, "[modified]", STATIC_SEQUENCE_COLOR_DEFAULT
moko_string_modified_end:

moko_string_scroll_up				db	"^[t4;"
					.c:	dw	STATIC_EMPTY
					.y:	dw	STATIC_EMPTY
						db	"]"
moko_string_scroll_up_end:

moko_string_scroll_down				db	"^[t5;"
					.c:	dw	STATIC_EMPTY
					.y:	dw	STATIC_EMPTY
						db	"]"
moko_string_scroll_down_end:

moko_key_ctrl_semaphore				db	STATIC_FALSE
moko_key_insert_semaphore			db	STATIC_FALSE

moko_string_console_header			db	"^[hMoko]"
moko_string_console_header_end:
