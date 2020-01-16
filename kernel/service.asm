;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
kernel_service:
	; usługa związana z procesem?
	cmp	al,	KERNEL_SERVICE_PROCESS
	je	.process

.end:
	; powrót z przerwania programowego
	iretq

;-------------------------------------------------------------------------------
.process:
	; koniec obsługi podprocedury
	jmp	kernel_service.end
