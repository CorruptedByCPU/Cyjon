;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_vfs:

.loop:
	; zwolnij pozostały czas procesora
	call	kernel_sleep

	; powrót do głównej pętli
	jmp	.loop

kernel_vfs_end:
