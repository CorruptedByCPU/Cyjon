;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

align	STATIC_QWORD_SIZE_byte,			db	STATIC_EMPTY
tm_stream_meta:
	times	KERNEL_STREAM_META_SIZE_byte	db	STATIC_EMPTY

tm_string_header				db	STATIC_ASCII_SEQUENCE_CURSOR_DISABLE, STATIC_ASCII_SEQUENCE_CLEAR, STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_RED_LIGHT, STATIC_ASCII_SEQUENCE_COLOR_BLACK, "Task Manager"
						db	"^[t1;1;2]", STATIC_ASCII_SEQUENCE_COLOR_DEFAULT, "{1,2 - cursor position}"
tm_string_header_end:

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
tm_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY
