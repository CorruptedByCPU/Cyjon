;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

shell_string_prompt_with_new_line	db	STATIC_ASCII_NEW_LINE
shell_string_prompt			db	STATIC_COLOR_ASCII_RED_LIGHT
shell_string_prompt_type		db	"# "
shell_string_prompt_type_end		db	STATIC_COLOR_ASCII_DEFAULT
shell_string_prompt_end:

shell_cache:
	times SHELL_CACHE_SIZE_byte	db	STATIC_EMPTY

shell_command_clean			db	"clean"
shell_command_clean_end:

shell_command_unknown			db	"?"
shell_command_unknown_end:
