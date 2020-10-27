;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

kernel_wm_semaphore					db	STATIC_FALSE
kernel_wm_pid						dq	STATIC_EMPTY

kernel_wm_object_semaphore				db	STATIC_FALSE
kernel_wm_object_arbiter_semaphore			db	STATIC_FALSE
kernel_wm_fill_semaphore				db	STATIC_FALSE
kernel_wm_zone_semaphore				db	STATIC_FALSE

kernel_wm_keyboard_alt_left_semaphore			db	STATIC_FALSE
kernel_wm_mouse_button_left_semaphore			db	STATIC_FALSE
kernel_wm_mouse_button_right_semaphore			db	STATIC_FALSE

kernel_wm_object_id_semaphore				db	STATIC_FALSE
kernel_wm_object_id					dq	0x01	; wartość podstawowa

align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING

kernel_wm_object_selected_pointer			dq	STATIC_EMPTY
kernel_wm_object_privileged_pid				dq	STATIC_EMPTY

kernel_wm_object_list_address				dq	STATIC_EMPTY
servide_desu_object_list_size_page			dq	1
kernel_wm_object_list_records				dq	STATIC_EMPTY
kernel_wm_object_list_records_free			dq	STATIC_PAGE_SIZE_byte / (KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE)
kernel_wm_object_list_modify_time			dq	STATIC_EMPTY

kernel_wm_fill_list_address				dq	STATIC_EMPTY

kernel_wm_zone_list_address				dq	STATIC_EMPTY
kernel_wm_zone_list_records				dq	STATIC_EMPTY

kernel_wm_ipc_data:
		times	KERNEL_IPC_STRUCTURE.SIZE	db	STATIC_EMPTY

;-------------------------------------------------------------------------------
kernel_wm_object_framebuffer:				dq	0
							dq	0
							dq	STATIC_EMPTY
							dq	STATIC_EMPTY
							dq	STATIC_EMPTY
.extra:							dq	STATIC_EMPTY
							dq	STATIC_EMPTY

;-------------------------------------------------------------------------------
kernel_wm_object_cursor:				dq	0
							dq	0
							dq	12
							dq	19
							dq	kernel_wm_object_cursor.data
.extra:							dq	kernel_wm_object_cursor.end - kernel_wm_object_cursor.data
							dq	KERNEL_WM_OBJECT_FLAG_pointer | KERNEL_WM_OBJECT_FLAG_flush | KERNEL_WM_OBJECT_FLAG_visible
							dq	STATIC_EMPTY	; obiekt kursora nie posiada identyfikatora
.data:							incbin	"kernel/service/wm/gfx/cursor.data"
.end:
