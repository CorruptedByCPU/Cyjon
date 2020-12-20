;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

shell_string_console_header			db	"^[hShell]"
shell_string_console_header_end:

shell_pid_parent				dq	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
shell_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY

shell_string_cursor_reset			db	"^[t1;"
					.c:	dd	STATIC_MAX_unsigned
					.y:	dd	STATIC_MAX_unsigned
						db	"]", STATIC_SCANCODE_NEW_LINE, STATIC_SEQUENCE_CURSOR_RESET
shell_string_cursor_reset_end:

shell_string_prompt_with_new_line		db	STATIC_SCANCODE_NEW_LINE
shell_string_prompt				db	STATIC_SEQUENCE_COLOR_RED_LIGHT
shell_string_prompt_type			db	"# "
shell_string_prompt_type_end			db	STATIC_SEQUENCE_COLOR_DEFAULT
shell_string_prompt_end:
shell_string_sequence_clear			db	STATIC_SEQUENCE_CLEAR
shell_string_sequence_clear_end:
shell_exec_path					db	"/bin/"
shell_exec_path_end:

shell_cache:
	times SHELL_CACHE_SIZE_byte		db	STATIC_EMPTY

shell_command_clear				db	"clear"
shell_command_clear_end:
shell_command_exit				db	"exit"
shell_command_exit_end:
shell_command_cd				db	"cd"
shell_command_cd_end:

shell_command_unknown				db	STATIC_SEQUENCE_COLOR_GREEN_LIGHT, "?", STATIC_SCANCODE_NEW_LINE
shell_command_unknown_end:

align	STATIC_QWORD_SIZE_byte,			db	STATIC_EMPTY
shell_stream_meta:
	times	KERNEL_STREAM_META_SIZE_byte	db	STATIC_EMPTY
