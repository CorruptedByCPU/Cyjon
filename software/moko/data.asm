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

moko_document_start_address			dq	STATIC_EMPTY
moko_document_end_address			dq	STATIC_EMPTY
moko_document_area_size				dq	MOKO_DOCUMENT_AREA_SIZE_default
moko_document_size				dq	STATIC_EMPTY
moko_document_line_index_last			dq	STATIC_EMPTY
moko_document_line_begin_last			dq	STATIC_EMPTY

moko_string_document_cursor			db	STATIC_SEQUENCE_CURSOR
moko_string_document_cursor_end:

moko_string_clear_and_cursor_at_menu		db	STATIC_SEQUENCE_CLEAR, "^[t1;0;*]"
moko_string_clear_and_cursor_at_menu_end:

moko_string_close				db	"^[t1;*;*]"
moko_string_close_end:

moko_string_menu:
					.exit	db	"^[c70]^x^[c07] Exit ", STATIC_SEQUENCE_COLOR_DEFAULT
					.exit_end:
moko_string_menu_end:

moko_key_ctrl_semaphore				db	STATIC_FALSE
moko_key_insert_semaphore			db	STATIC_FALSE
