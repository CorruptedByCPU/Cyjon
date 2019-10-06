;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

kernel_init_video:
	; wyczyść przestrzeń pamięci trybu tekstowego
	call	kernel_video_dump

	; wyświetl powitanie
	mov	ecx,	kernel_init_string_video_welcome_end - kernel_init_string_video_welcome
	mov	rsi,	kernel_init_string_video_welcome
	call	kernel_video_string
