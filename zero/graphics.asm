;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

ZERO_GRAPHICS_MODE_INFO_BLOCK_SIZE_byte	equ	0x1000

ZERO_GRAPHICS_DEPTH_bit			equ	32
ZERO_GRAPHICS_MODE_clean		equ	0x8000
ZERO_GRAPHICS_MODE_linear		equ	0x4000

struc	ZERO_STRUCTURE_GRAPHICS_VGA_INFO_BLOCK
	.vesa_signature			resb	4
	.vesa_version			resb	2
	.oem_string_ptr			resb	4
	.capabilities			resb	4
	.video_mode_ptr			resb	4
	.total_memory			resb	2
	.reserved			resb	236
endstruc

struc	ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK
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
zero_graphics:
	; wyrównaj adres końca mapy pamięci do pełnej strony
	call	zero_page_align_up

	; zachowaj adres tablicy GRAPHICS_MODE_INFO_BLOCK
	mov	dword [zero_graphics_mode_info_block_address],	edi

	; pobierz dostępne tryby graficzne
	mov	ax,	0x4F00
	add	edi,	ZERO_GRAPHICS_MODE_INFO_BLOCK_SIZE_byte
	int	0x10

	; funkcja wywołana prawidłowo?
	test	ax,	0x4F00
	jnz	.error	; nie

	; przeszukaj tablicę dostępnych trybów za porządanym
	mov	esi,	dword [di + ZERO_STRUCTURE_GRAPHICS_VGA_INFO_BLOCK.video_mode_ptr]

.loop:
	; koniec tablicy?
	cmp	word [esi],	0xFFFF
	je	.error	; tak

	; pobierz właściwości danego trybu graficznego
	mov	ax,	0x4F01
	mov	cx,	word [esi]
	mov	edi,	dword [zero_graphics_mode_info_block_address]
	int	0x10

	; oczekiwana szerokość w pikselach?
	cmp	word [di + ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.x_resolution],	SELECTED_VIDEO_WIDTH_pixel
	jne	.next	; nie

	; oczekiwana wysokość w pikselach?
	cmp	word [di + ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.y_resolution],	SELECTED_VIDEO_HEIGHT_pixel
	jne	.next	; nie

	; oczekiwana głębia kolorów?
	cmp	byte [di + ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.bits_per_pixel],	ZERO_GRAPHICS_DEPTH_bit
	je	.found	; tak

.next:
	; przesuń wskaźnik na następny wpis
	add	esi,	0x02

	; sprawdź następny tryb
	jmp	.loop

.error:
	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

.found:
	; włącz dany tryb graficzny
	mov	ax,	0x4F02
	mov	bx,	word [esi]
	or	bx,	ZERO_GRAPHICS_MODE_linear | ZERO_GRAPHICS_MODE_clean
	int	0x10

	; operacja wykonana pomyślnie?
	test	ah,	ah
	jnz	.error	; nie
