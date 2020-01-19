;===============================================================================
; Copyright (C) by Andrzej Adamczyk at Wataha.net
;===============================================================================

init_string_logo	db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_BLUE_LIGHT, "    B l a c k e n d . d e v", STATIC_ASCII_NEW_LINE
			db	STATIC_COLOR_ASCII_GRAY, "  ---------------------------", STATIC_ASCII_NEW_LINE, STATIC_ASCII_NEW_LINE
init_string_logo_end:

init_program_shell	db	"/bin/shell"
init_program_shell_end:
