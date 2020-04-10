;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_INIT_MEMORY_MULTIBOOT_FLAG_video	equ	12

;===============================================================================
kernel_init_video:
	; zachowaj oryginalny rejestr
	push	rbx

	; nagłówek udostępnia mapę pamięci BIOSu?
	bt	dword [ebx + MULTIBOOT_HEADER.flags],	KERNEL_INIT_MEMORY_MULTIBOOT_FLAG_video
	jnc	kernel_panic	; błąd krytyczny

	; pobierz i zachowaj adres przestrzeni pamięci karty graficznej
	mov	edi,	dword [ebx + MULTIBOOT_HEADER.framebuffer_addr]
	mov	qword [kernel_video_base_address],	rdi

	; pobierz i zachowaj rozdzielczość
	mov	eax,	dword [ebx + MULTIBOOT_HEADER.framebuffer_width]
	mov	qword [kernel_video_width_pixel],	rax
	mov	eax,	dword [ebx + MULTIBOOT_HEADER.framebuffer_height]
	mov	qword [kernel_video_height_pixel],	rax

	; rozmiar przestrzeni pamięci karty graficznej w Bajtach
	mul	qword [kernel_video_width_pixel]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	mov	qword [kernel_video_size_byte],	rax

	; scanline ekranu
	mov	rax,	qword [kernel_video_width_pixel]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	mov	qword [kernel_video_scanline_byte],	rax

	; przywróć oryginalny rejestry
	pop	rbx
