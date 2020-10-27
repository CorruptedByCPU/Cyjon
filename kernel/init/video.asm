;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

struc	KERNEL_INIT_VIDEO_STRUCTURE_MODE_INFO_BLOCK
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

;===============================================================================
kernel_init_video:
	; pobierz i zachowaj adres przestrzeni pamięci karty graficznej
	mov	edi,	dword [edx + KERNEL_INIT_VIDEO_STRUCTURE_MODE_INFO_BLOCK.physical_base_address]
	mov	qword [kernel_video_base_address],	rdi

	; pobierz i zachowaj rozdzielczość
	movzx	eax,	word [edx + KERNEL_INIT_VIDEO_STRUCTURE_MODE_INFO_BLOCK.x_resolution]
	mov	qword [kernel_video_width_pixel],	rax
	mov	ax,	word [edx + KERNEL_INIT_VIDEO_STRUCTURE_MODE_INFO_BLOCK.y_resolution]
	mov	qword [kernel_video_height_pixel],	rax

	; rozmiar przestrzeni pamięci karty graficznej w Bajtach
	mul	qword [kernel_video_width_pixel]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	mov	qword [kernel_video_size_byte],	rax

	; scanline ekranu
	mov	rax,	qword [kernel_video_width_pixel]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	mov	qword [kernel_video_scanline_byte],	rax
