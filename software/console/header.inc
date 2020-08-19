;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

CONSOLE_IPC_COMMAND_properties	equ	0x00
CONSOLE_IPC_COMMAND_cursor_set	equ	0x01

struc	CONSOLE_STRUCTURE_IPC
	.command		resb	1
	.reserved		resb	7
	.width			resb	8
	.height			resb	8
	.cursor:		resb	4	; pozycja na osi X
				resb	4	; pozycja na osi Y
endstruc

struc	CONSOLE_STRUCTURE_CURSOR
	.x			resb	4
	.y			resb	4
endstruc

struc	CONSOLE_STRUCTURE_WINDOW_META
	.width			resb	2
	.height			resb	2
	.x			resb	2
	.y			resb	2
endstruc
