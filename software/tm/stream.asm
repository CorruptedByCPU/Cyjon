;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
tm_stream_info:
	; pobierz informacje o strumieniu wyjścia
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	mov	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_get | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_out
	mov	ecx,	CONSOLE_STRUCTURE_STREAM_META.SIZE
	mov	rdi,	tm_stream_meta
	int	KERNEL_SERVICE
	jc	tm_stream_info	; brak aktualnych informacji

	; powrót z procedury
	ret
