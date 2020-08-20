;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
; UWAGA:
;	rejestry zniszczone
console_meta:
	; zachowaj oryginalne rejestry
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	mov	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_set | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_in
	mov	ecx,	CONSOLE_STRUCTURE_STREAM_META.SIZE
	mov	rsi,	console_stream_meta
	int	KERNEL_SERVICE

	; powrót z procedury
	ret
