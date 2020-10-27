;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

shell_pid_parent				dq	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
shell_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY

shell_string_cursor_enable			db	STATIC_ASCII_SEQUENCE_CURSOR_ENABLE
shell_string_cursor_enable_end:

shell_string_prompt_with_new_line		db	STATIC_ASCII_NEW_LINE
shell_string_prompt				db	STATIC_ASCII_SEQUENCE_COLOR_RED_LIGHT
shell_string_prompt_type			db	"# "
shell_string_prompt_type_end			db	STATIC_ASCII_SEQUENCE_COLOR_DEFAULT
shell_string_prompt_end:
shell_string_sequence_clear			db	STATIC_ASCII_SEQUENCE_CLEAR
shell_string_sequence_clear_end:
shell_exec_path					db	"/bin/"
shell_exec_path_end:

shell_cache:
	times SHELL_CACHE_SIZE_byte		db	STATIC_EMPTY

shell_command_clear				db	"clear"
shell_command_clear_end:
shell_command_exit				db	"exit"
shell_command_exit_end:

shell_command_unknown				db	STATIC_ASCII_SEQUENCE_COLOR_RED_LIGHT, " ?", STATIC_ASCII_NEW_LINE
shell_command_unknown_end:

align	STATIC_QWORD_SIZE_byte,			db	STATIC_EMPTY
shell_stream_meta:
	times	KERNEL_STREAM_META_SIZE_byte	db	STATIC_EMPTY
