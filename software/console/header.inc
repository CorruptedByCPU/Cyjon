;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
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
