;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_wm_flush:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; bufor został zmodyfikowany?
	test	word [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush
	jz	.end	; nie

	; synchronizuj przestrzeń bufora z pamięcią karty graficznej
	mov	ecx,	dword [kernel_video_size_byte]
	mov	rsi,	qword [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.address]
	mov	rdi,	qword [kernel_video_base_address]
	call	kernel_memory_copy

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret
