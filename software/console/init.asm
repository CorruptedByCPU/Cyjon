;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	; przydziel przestrzeń pod dane okna
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_alloc
	mov	ecx,	(CONSOLE_WINDOW_WIDTH_pixel * CONSOLE_WINDOW_HEIGHT_pixel) << KERNEL_VIDEO_DEPTH_shift
	int	KERNEL_SERVICE
