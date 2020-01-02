;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_INIT_MEMORY_MULTIBOOT_FLAG_video	equ	12

;===============================================================================
kernel_init_video:
	; nagłówek udostępnia mapę pamięci BIOSu?
	bt	dword [ebx + HEADER_multiboot.flags],	KERNEL_INIT_MEMORY_MULTIBOOT_FLAG_video
	jnc	kernel_panic	; błąd krytyczny

	; pobierz i zachowaj adres przestrzeni pamięci karty graficznej
	mov	edi,	dword [ebx + HEADER_multiboot.framebuffer_addr]
	mov	qword [kernel_video_base_address],	rdi
	mov	qword [kernel_video_pointer],	rdi

	; pobierz szerokość i wysokość
	mov	eax,	dword [ebx + HEADER_multiboot.framebuffer_height]
	mov	dword [kernel_video_height_pixel],	eax
	mov	eax,	dword [ebx + HEADER_multiboot.framebuffer_width]
	mov	dword [kernel_video_width_pixel],	eax

	; wylicz scanline zbudowany z tekstu
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	mul	dword [kernel_font_height_pixel]
	mov	qword [kernel_video_scanline_char],	rax

	; wyczyść przestrzeń pamięci karty graficznej
	call	kernel_video_drain

	mov	ecx,	kernel_string_welcome_end - kernel_string_welcome
	mov	rsi,	kernel_string_welcome
	call	kernel_video_string
