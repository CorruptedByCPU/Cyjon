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

service_shell_command_clean			db	"clean"
service_shell_command_clean_end:
service_shell_command_ip			db	"ip"
service_shell_command_ip_end:
service_shell_command_ip_set			db	"set"
service_shell_command_ip_set_end:
service_shell_command_ls			db	"ls"
service_shell_command_ls_end:

service_shell_command_unknown			db	"?"
service_shell_command_unknown_end:

service_shell_string_error_ipv4_format		db	STATIC_ASCII_NEW_LINE, "Wrong IPv4 address."
service_shell_string_error_ipv4_format_end:
