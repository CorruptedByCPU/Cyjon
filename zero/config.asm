;================================================================================
; Copyright (C) by Blackend.dev
;================================================================================

;-------------------------------------------------------------------------------
; tryb programu rozruchowego
;-------------------------------------------------------------------------------
STATIC_ZERO_bit_mode			equ	32	; dostępne wartości: 16, 32

;-------------------------------------------------------------------------------
; "zmienne" globalne
;-------------------------------------------------------------------------------

STATIC_ZERO_address			equ	0x7C00	; 0x0000:0x7C00
STATIC_ZERO_stack			equ	STATIC_ZERO_address
STATIC_ZERO_magic			equ	0xAA55
STATIC_ZERO_kernel_address		equ	0x1000	; 0x1000:0x0000
STATIC_ZERO_memory_map			equ	0x1000	; 0x0000:0x1000
STATIC_ZERO_multiboot_header		equ	0x0500	; 0x0000:0x0500
STATIC_ZERO_video_vga_info_block	equ	0x2000	; 0x0000:0x2000
STATIC_ZERO_video_mode_info_block	equ	0x3000	; 0x0000:0x3000

STATIC_ZERO_VIDEO_WIDTH_pixel		equ	1920
STATIC_ZERO_VIDEO_HEIGHT_pixel		equ	1080
STATIC_ZERO_VIDEO_DEPTH_bit		equ	32
STATIC_ZERO_VIDEO_MODE_clean		equ	0x8000
STATIC_ZERO_VIDEO_MODE_linear		equ	0x4000

STATIC_ZERO_ERROR_a20			equ	0x4F41	; "A"
STATIC_ZERO_ERROR_memory		equ	0x4F4D	; "M"
STATIC_ZERO_ERROR_disk			equ	0x4F44	; "D"
STATIC_ZERO_ERROR_video			equ	0x4F56	; "V"

STATIC_WORD_SIZE_byte			equ	0x02

STATIC_EMPTY				equ	0x00

STATIC_FALSE				equ	0x01
STATIC_TRUE				equ	0x00

STATIC_SECTOR_SIZE_byte			equ	0x0200

STATIC_SEGMENT_to_pointer		equ	4
STATIC_SEGMENT_SIZE_byte		equ	0x1000

STATIC_MULTIBOOT_HEADER_FLAG_memory_map	equ	1 << 6
STATIC_MULTIBOOT_HEADER_FLAG_video	equ	1 << 12

struc	STATIC_MULTIBOOT_header
	.flags			resb	4
	.unsupported0		resb	40
	.mmap_length		resb	4
	.mmap_addr		resb	4
	.unsupported1		resb	36
	.framebuffer_addr	resb	8
	.framebuffer_pitch	resb	4
	.framebuffer_width	resb	4
	.framebuffer_height	resb	4
	.framebuffer_bpp	resb	1
	.framebuffer_type	resb	1
	.color_info		resb	6
endstruc

struc	STATIC_ZERO_VIDEO_STRUCTURE_VGA_INFO_BLOCK
	.vesa_signature			resb	4
	.vesa_version			resb	2
	.oem_string_ptr			resb	4
	.capabilities			resb	4
	.video_mode_ptr			resb	4
	.total_memory			resb	2
	.reserved			resb	236
	.SIZE:
endstruc

struc	STATIC_ZERO_VIDEO_STRUCTURE_MODE_INFO_BLOCK
	.mode_attributes		resb	2
	.win_a_attributes		resb	1
	.win_b_attributes		resb	1
	.win_granularity		resb	2
	.win_size			resb	2
	.win_a_segment			resb	2
	.win_b_segment			resb	2
	.win_func_ptr			resb	4
	.bytes_per_scanline		resb	2
	.x_resolution			resb	2
	.y_resolution			resb	2
	.x_char_size			resb	1
	.y_char_size			resb	1
	.number_of_planes		resb	1
	.bits_per_pixel			resb	1
	.number_of_banks		resb	1
	.memory_model			resb	1
	.bank_size			resb	1
	.number_of_image_pages		resb	1
	.reserved0			resb	1
	.red_mask_size			resb	1
	.red_field_position		resb	1
	.green_mask_size		resb	1
	.green_field_position		resb	1
	.blue_mask_size			resb	1
	.blue_field_position		resb	1
	.rsvd_mask_size			resb	1
	.direct_color_mode_info		resb	2
	.physical_base_address		resb	4
	.reserved1			resb	212
endstruc

;-------------------------------------------------------------------------------
; stałe i zmienne dla kontrolerów wbudowanych
;-------------------------------------------------------------------------------

DRIVER_PIT_PORT_command			equ	0x0043

DRIVER_PIC_PORT_MASTER_data		equ	0x0021
DRIVER_PIC_PORT_SLAVE_data		equ	0x00A1
