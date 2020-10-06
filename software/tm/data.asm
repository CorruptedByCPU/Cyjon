;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

align	STATIC_QWORD_SIZE_byte,			db	STATIC_EMPTY
tm_stream_meta:
	times	KERNEL_STREAM_META_SIZE_byte	db	STATIC_EMPTY

tm_string_init					db	STATIC_ASCII_SEQUENCE_CURSOR_DISABLE, STATIC_ASCII_SEQUENCE_CLEAR
tm_string_init_end:

tm_string_ram					db	"^[t1;1;1]", STATIC_ASCII_SEQUENCE_COLOR_DEFAULT, "Ram "
tm_string_ram_end:
tm_string_ram_part_one				db	STATIC_ASCII_SEQUENCE_COLOR_WHITE, STATIC_ASCII_SEQUENCE_COLOR_BACKGROUND_BLACK
tm_string_ram_part_one_end:
tm_string_ram_part_two				db	STATIC_ASCII_SEQUENCE_COLOR_GRAY
tm_string_ram_part_two_end:
tm_string_ram_part_tree				db	STATIC_ASCII_SEQUENCE_COLOR_GRAY_LIGHT
tm_string_ram_part_tree_end:

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
tm_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY

tm_string_size_values				db	"BKMGTPEZY"
tm_string_ram_value		times	0x07	db	STATIC_EMPTY
