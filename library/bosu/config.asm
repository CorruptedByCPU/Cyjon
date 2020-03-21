;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;-------------------------------------------------------------------------------
LIBRARY_BOSU_WINDOW_FLAG_visible		equ	1 << 0	; okno widoczne
LIBRARY_BOSU_WINDOW_FLAG_flush			equ	1 << 1	; okno wymaga przerysowania
LIBRARY_BOSU_WINDOW_FLAG_fixed_xy		equ	1 << 2	; okno nieruchome na osi X,Y
LIBRARY_BOSU_WINDOW_FLAG_fixed_z		equ	1 << 3	; okno nieruchome na osi Z
LIBRARY_BOSU_WINDOW_FLAG_fragile		equ	1 << 4	; okno ukrywane przy wystąpieniu akcji z LPM lub PPM
LIBRARY_BOSU_WINDOW_FLAG_arbiter		equ	1 << 6	; nadobiekt
							; powyżej 7, przeznaczone dla GUI
LIBRARY_BOSU_WINDOW_FLAG_header			equ	1 << 8
LIBRARY_BOSU_WINDOW_FLAG_border			equ	1 << 9
;-------------------------------------------------------------------------------

LIBRARY_BOSU_ELEMENT_TYPE_none			equ	0x00
LIBRARY_BOSU_ELEMENT_TYPE_header		equ	0x01
LIBRARY_BOSU_ELEMENT_TYPE_label			equ	0x02
LIBRARY_BOSU_ELEMENT_TYPE_draw			equ	0x03
LIBRARY_BOSU_ELEMENT_TYPE_chain			equ	0x04
LIBRARY_BOSU_ELEMENT_TYPE_button		equ	0x05

struc	LIBRARY_BOSU_STRUCTURE_FIELD
	.x					resb	8
	.y					resb	8
	.width					resb	8
	.height					resb	8
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_WINDOW
	.field					resb	LIBRARY_BOSU_STRUCTURE_FIELD.SIZE
	.address				resb	8
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA
	.size					resb	8
	.flags					resb	8
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT
	.type					resb	4
	.size					resb	8
	.field					resb	LIBRARY_BOSU_STRUCTURE_FIELD.SIZE
	.event					resb	8
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_HEADER
	.type					resb	1
	.size					resb	2
	.length					resb	1
	.string:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL
	.element				resb	LIBRARY_BOSU_STRUCTURE_ELEMENT.SIZE
	.length					resb	1
	.string:
	.SIZE:
endstruc

struc	LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON
	.element				resb	LIBRARY_BOSU_STRUCTURE_ELEMENT.SIZE
	.length					resb	1
	.string:
	.SIZE:
endstruc
