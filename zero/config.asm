;================================================================================
; Copyright (C) by Blackend.dev
;================================================================================

;-------------------------------------------------------------------------------
; tryb programu rozruchowego
;-------------------------------------------------------------------------------
STATIC_ZERO_bit_mode			equ	32	; dostępne wartości: 16, 32 i 64


;-------------------------------------------------------------------------------
; "zmienne" globalne
;-------------------------------------------------------------------------------

STATIC_ZERO_address			equ	0x7C00
STATIC_ZERO_stack			equ	0x8000
STATIC_ZERO_magic			equ	0xAA55
STATIC_ZERO_kernel_address		equ	0x1000	; 0x1000:0x0000
STATIC_ZERO_memory_map			equ	0x1000	; 0x0000:0x1000
STATIC_ZERO_multiboot_header		equ	0x0500

STATIC_ZERO_ERROR_memory		equ	0x4F4D	; "M"
STATIC_ZERO_ERROR_device		equ	0x4F44	; "D"

STATIC_EMPTY				equ	0x00

STATIC_FALSE				equ	0x01
STATIC_TRUE				equ	0x00

STATIC_SECTOR_SIZE_byte			equ	0x0200

STATIC_SEGMENT_to_pointer		equ	4

STATIC_PML4_TABLE_address		equ	0x0000A000

STATIC_PAGE_SIZE_4KiB_byte		equ	0x1000
STATIC_PAGE_SIZE_2MiB_byte		equ	0x00200000

STATIC_PAGE_FLAG_available		equ	00000001b
STATIC_PAGE_FLAG_writeable		equ	00000010b
STATIC_PAGE_FLAG_2MiB_size		equ	10000000b
STATIC_PAGE_FLAG_default		equ	STATIC_PAGE_FLAG_available | STATIC_PAGE_FLAG_writeable

STATIC_MULTIBOOT_HEADER_FLAG_memory_map	equ	01000000b

struc	STATIC_MULTIBOOT_header
	.flags		resb	4
	.unsupported	resb	40
	.mmap_length	resb	4
	.mmap_addr	resb	4
endstruc

;-------------------------------------------------------------------------------
; stałe i zmienne dla kontrolerów wbudowanych
;-------------------------------------------------------------------------------

DRIVER_PIT_PORT_command			equ	0x0043
DRIVER_PIT_COMMAND_access_low_high	equ	00110000b


DRIVER_PIC_PORT_MASTER_data		equ	0x0021
DRIVER_PIC_PORT_SLAVE_data		equ	0x00A1
