;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

struc	LIBRARY_RGL_STRUCTURE_PROPERTIES
	.width			resb	2
	.height			resb	2
	.address		resb	8
	.size			resb	8
	.scanline		resb	8
	.background_color	resb	4
endstruc

struc	LIBRARY_RGL_STRUCTURE_SQUARE
	.x			resb	2
	.y			resb	2
	.width			resb	2
	.height			resb	2
	.color			resb	4
endstruc
