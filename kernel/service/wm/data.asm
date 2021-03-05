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

kernel_wm_zone_semaphore				db	STATIC_FALSE

kernel_wm_keyboard_alt_left_semaphore			db	STATIC_FALSE
kernel_wm_mouse_button_left_semaphore			db	STATIC_FALSE
kernel_wm_mouse_button_right_semaphore			db	STATIC_FALSE

kernel_wm_object_id_semaphore				db	STATIC_FALSE
kernel_wm_object_id					dq	0x01	; wartość podstawowa

align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING

kernel_wm_object_active_pointer				dq	STATIC_EMPTY
kernel_wm_object_selected_pointer			dq	STATIC_EMPTY
kernel_wm_object_privileged_pid				dq	STATIC_EMPTY

kernel_wm_object_list_address				dq	STATIC_EMPTY
kernel_wm_object_list_length				dq	STATIC_EMPTY
kernel_wm_object_list_modify_time			dq	STATIC_EMPTY

kernel_wm_object_table_address				dq	STATIC_EMPTY

kernel_wm_fill_list_address				dq	STATIC_EMPTY

kernel_wm_zone_list_address				dq	STATIC_EMPTY
kernel_wm_zone_list_records				dq	STATIC_EMPTY

kernel_wm_merge_list_address				dq	STATIC_EMPTY
kernel_wm_merge_list_records				dq	STATIC_EMPTY

kernel_wm_ipc_data:
		times	KERNEL_IPC_STRUCTURE.SIZE	db	STATIC_EMPTY

;-------------------------------------------------------------------------------
kernel_wm_object_framebuffer:				dw	0
							dw	0
							dw	STATIC_EMPTY
							dw	STATIC_EMPTY
							dq	STATIC_EMPTY
.extra:							dd	STATIC_EMPTY
							dq	STATIC_EMPTY

;-------------------------------------------------------------------------------
kernel_wm_object_cursor:				dw	0
							dw	0
							dw	12
							dw	19
							dq	kernel_wm_object_cursor.data
.extra:							dd	kernel_wm_object_cursor.end - kernel_wm_object_cursor.data
							dw	KERNEL_WM_OBJECT_FLAG_pointer | KERNEL_WM_OBJECT_FLAG_flush | KERNEL_WM_OBJECT_FLAG_visible
							dq	STATIC_EMPTY	; obiekt kursora nie posiada identyfikatora
.data:							incbin	"kernel/service/wm/gfx/cursor.data"
.end:
