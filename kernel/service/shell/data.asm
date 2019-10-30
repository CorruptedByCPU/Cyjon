;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

service_shell_string_prompt_with_new_line	db	STATIC_ASCII_NEW_LINE
service_shell_string_prompt			db	STATIC_COLOR_ASCII_RED_LIGHT
service_shell_string_prompt_type		db	"# "
service_shell_string_prompt_type_end		db	STATIC_COLOR_ASCII_DEFAULT
service_shell_string_prompt_end:

service_shell_cache:
	times SERVICE_SHELL_CACHE_SIZE_byte	db	STATIC_EMPTY
