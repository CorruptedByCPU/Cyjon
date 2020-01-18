;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
kernel_service:
	; usługa związana z procesem?
	cmp	al,	KERNEL_SERVICE_PROCESS
	je	.process	; tak

	; obsługa przestrzeni konsoli?
	cmp	al,	KERNEL_SERVICE_VIDEO
	je	.video	 ; tak

.end:
	; powrót z przerwania programowego
	iretq

;-------------------------------------------------------------------------------
.process:
	; zakończ pracę procesu?
	cmp	ax,	KERNEL_SERVICE_PROCESS_exit
	je	kernel_task_kill	; tak

	; koniec obsługi podprocedury
	jmp	kernel_service.end

;-------------------------------------------------------------------------------
.video:
	; wyświetlić ciąg znaków w konsoli?
	cmp	ax,	KERNEL_SERVICE_VIDEO_string
	jne	.video_no_string	; nie

	; wyświetl ciąg w konsoli
	call	kernel_video_string

	; koniec obsługi podprocedury
	jmp	kernel_service.end

.video_no_string:
	; koniec obsługi podprocedury
	jmp	kernel_service.end
