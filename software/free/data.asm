;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

free_string_table	db	STATIC_COLOR_ASCII_GRAY, "        total         used          free          paged", STATIC_ASCII_NEW_LINE
			db	STATIC_COLOR_ASCII_GRAY_LIGHT, "Memory: ", STATIC_COLOR_ASCII_WHITE
free_string_table_end:

free_string_kib		db	STATIC_COLOR_ASCII_GRAY_LIGHT, " KiB", STATIC_COLOR_ASCII_WHITE
free_string_kib_end:
