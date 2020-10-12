;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

struc	CONSOLE_STRUCTURE_CURSOR
	.x			resb	4
	.y			resb	4
endstruc

struc	CONSOLE_STRUCTURE_STREAM_META
	.width			resb	2
	.height			resb	2
	.x			resb	2
	.y			resb	2
	.SIZE:
endstruc
