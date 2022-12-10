;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	interchangeably
sys_request:
	; preserve original registers
	push	rcx
	push	r11

	; execute request
	syscall

	; restore original registers
	pop	r11
	pop	rcx

	; return from routine
	ret