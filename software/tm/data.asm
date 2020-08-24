;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

align	STATIC_QWORD_SIZE_byte,			db	STATIC_EMPTY
tm_stream_meta:
	times	KERNEL_STREAM_META_SIZE_byte	db	STATIC_EMPTY

tm_string_header				db	STATIC_ASCII_SEQUENCE_CLEAR, STATIC_ASCII_SEQUENCE_CURSOR_DISABLE, STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_RED, STATIC_ASCII_SEQUENCE_COLOR_BLACK, "Task Manager", STATIC_ASCII_SEQUENCE_COLOR_DEFAULT, STATIC_ASCII_NEW_LINE
tm_string_header_end:

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
tm_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY
