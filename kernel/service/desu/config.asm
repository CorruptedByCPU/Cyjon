;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

SERVICE_DESU_OBJECT_NAME_length				equ	8

SERVICE_DESU_OBJECT_FLAG_visible			equ	1 << 0	; obiekt widoczny
SERVICE_DESU_OBJECT_FLAG_flush				equ	1 << 1	; obiekt został zaktualizowany
; poniższe flagi są zarezerwowane dla GUI
SERVICE_DESU_OBJECT_FLAG_fixed_xy			equ	1 << 2	; obiekt nieruchomy na osi X,Y
SERVICE_DESU_OBJECT_FLAG_fixed_z			equ	1 << 3	; obiekt nieruchomy na osi Z
SERVICE_DESU_OBJECT_FLAG_fragile			equ	1 << 4	; obiekt ukrywany przy wystąpieniu akcji z LPM lub PPM
SERVICE_DESU_OBJECT_FLAG_pointer			equ	1 << 5	; obiekt typu "kursor"
SERVICE_DESU_OBJECT_FLAG_arbiter			equ	1 << 6	; nadobiekt

SERVICE_DESU_FILL_LIST_limit				equ	(KERNEL_PAGE_SIZE_byte / SERVICE_DESU_STRUCTURE_FILL.SIZE) - 0x01
SERVICE_DESU_ZONE_LIST_limit				equ	(KERNEL_PAGE_SIZE_byte / SERVICE_DESU_STRUCTURE_ZONE.SIZE) - 0x01

struc	SERVICE_DESU_STRUCTURE_FIELD
	.x						resb	8
	.y						resb	8
	.width						resb	8
	.height						resb	8
	.SIZE:
endstruc

struc	SERVICE_DESU_STRUCTURE_OBJECT
	.field						resb	SERVICE_DESU_STRUCTURE_FIELD.SIZE
	.address					resb	8
	.SIZE:
endstruc

struc	SERVICE_DESU_STRUCTURE_OBJECT_EXTRA
	.size						resb	8
	.flags						resb	8
	.SIZE:
endstruc

struc	SERVICE_DESU_STRUCTURE_FILL
	.field						resb	SERVICE_DESU_STRUCTURE_FIELD.SIZE
	.object						resb	8
	.SIZE:
endstruc

struc	SERVICE_DESU_STRUCTURE_ZONE
	.field						resb	SERVICE_DESU_STRUCTURE_FIELD.SIZE
	.object						resb	8
	.SIZE:
endstruc

;===============================================================================
;===============================================================================

SERVICE_DESU_COLOR_base				equ	0x00181818

SERVICE_DESU_OBJECT_FLAG_mask_unprivileged	equ	SERVICE_DESU_OBJECT_FLAG_visible | SERVICE_DESU_OBJECT_FLAG_flush

SERVICE_DESU_OBJECT_ERROR_full			equ	0x01
SERVICE_DESU_OBJECT_ERROR_memory_low		equ	0x02
SERVICE_DESU_OBJECT_ERROR_corruped		equ	0x03

SERVICE_DESU_UPDATE_LIST_size_page		equ	0x01
SERVICE_DESU_UPDATE_LIST_amount_limit		equ	((SERVICE_DESU_UPDATE_LIST_size_page << KERNEL_PAGE_SIZE_shift) / SERVICE_DESU_STRUCTURE_OBJECT.SIZE) - 0x01

SERVICE_DESU_SHADOW_LIST_size_page		equ	0x01
SERVICE_DESU_SHADOW_LIST_amount_limit		equ	((SERVICE_DESU_SHADOW_LIST_size_page << KERNEL_PAGE_SIZE_shift) / SERVICE_DESU_STRUCTURE_OBJECT.SIZE) - 0x01
