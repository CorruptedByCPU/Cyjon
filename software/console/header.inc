;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

CONSOLE_IPC_FLAG_properties	equ	00000000b
CONSOLE_IPC_FLAG_cursor_set	equ	00000001b

struc	CONSOLE_STRUCTURE_IPC
	.flags			resb	1
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
