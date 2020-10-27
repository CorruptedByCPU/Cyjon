;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; INIT
;===============================================================================
kernel_init_semaphore					db	STATIC_TRUE

kernel_init_exec					db	"/bin/init"
kernel_init_exec_end:

;===============================================================================
; GDT
;===============================================================================
; wyrównaj pozycję nagłówka do pełnego adresu
align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING
kernel_gdt_header					dw	STATIC_PAGE_SIZE_byte
							dq	STATIC_EMPTY

; wyrównaj miejsca wskaźników do pełnego adresu
align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING
kernel_gdt_tss_bsp_selector				dw	STATIC_EMPTY
kernel_gdt_tss_cpu_selector				dw	STATIC_EMPTY

; wyrównaj pozycję tablicy do pełnego adresu
align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING
kernel_gdt_tss_table:
							dd	STATIC_EMPTY
							dq	KERNEL_STACK_pointer	; RSP0
					times	92	db	STATIC_EMPTY
kernel_gdt_tss_table_end:

;===============================================================================
; IDT
;===============================================================================
; wyrównaj pozycję nagłówka do pełnego adresu
align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING
kernel_idt_header:
							dw	STATIC_PAGE_SIZE_byte
							dq	STATIC_EMPTY

macro_debug	"kernel_data"

;===============================================================================
; VIDEO
;===============================================================================
;===============================================================================
kernel_video_width_pixel				dq	STATIC_EMPTY	; szerokość w pikselach
kernel_video_height_pixel				dq	STATIC_EMPTY	; wysokość w pikselach
kernel_video_base_address				dq	STATIC_EMPTY	; wskaźnik do przestrzeni danych terminala
kernel_video_size_byte					dq	STATIC_EMPTY	; rozmiar przestrzeni w Bajtach
kernel_video_scanline_byte				dq	STATIC_EMPTY	; scanline_byte
