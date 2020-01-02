;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

SERVICE_SHELL_CACHE_SIZE_byte	equ	(KERNEL_VIDEO_WIDTH_pixel / KERNEL_FONT_WIDTH_pixel) - (service_shell_string_prompt_type_end - service_shell_string_prompt_type) - 0x01
