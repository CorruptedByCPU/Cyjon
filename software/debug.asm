;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

; 64 bit code
[bits 64]

; main initialization procedure of kernel environment
global	entry

entry:
	; hold the door
	jmp	$
