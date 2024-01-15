;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

[BITS 64]

key_ctrl_push:
	mov	byte [variable_semaphore_key_ctrl],	VARIABLE_TRUE

	jmp	start.noKey

key_ctrl_pull:
	mov	byte [variable_semaphore_key_ctrl],	VARIABLE_FALSE

	jmp	start.noKey
