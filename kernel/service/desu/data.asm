;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

service_desu_semaphore					db	STATIC_FALSE
service_desu_pid					dq	STATIC_EMPTY

service_desu_object_semaphore				db	STATIC_FALSE
service_desu_object_arbiter_semaphore			db	STATIC_FALSE
service_desu_fill_semaphore				db	STATIC_FALSE
service_desu_zone_semaphore				db	STATIC_FALSE

service_desu_keyboard_alt_left_semaphore		db	STATIC_FALSE
service_desu_mouse_button_left_semaphore		db	STATIC_FALSE
service_desu_mouse_button_right_semaphore		db	STATIC_FALSE

service_desu_object_id_semaphore			db	STATIC_FALSE
service_desu_object_id					dq	0x01	; wartość podstawowa

align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING

service_desu_object_selected_pointer			dq	STATIC_EMPTY
service_desu_object_privileged_pid			dq	STATIC_EMPTY

service_desu_object_list_address			dq	STATIC_EMPTY
servide_desu_object_list_size_page			dq	1
service_desu_object_list_records			dq	STATIC_EMPTY
service_desu_object_list_records_free			dq	KERNEL_PAGE_SIZE_byte / (SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE)
service_desu_object_list_modify_time			dq	STATIC_EMPTY

service_desu_fill_list_address				dq	STATIC_EMPTY

service_desu_zone_list_address				dq	STATIC_EMPTY
service_desu_zone_list_records				dq	STATIC_EMPTY

service_desu_ipc_data:
		times	KERNEL_IPC_STRUCTURE.SIZE	db	STATIC_EMPTY

;-------------------------------------------------------------------------------
service_desu_object_framebuffer:			dq	0
							dq	0
							dq	STATIC_EMPTY
							dq	STATIC_EMPTY
							dq	STATIC_EMPTY
.extra:							dq	STATIC_EMPTY
							dq	STATIC_EMPTY

;-------------------------------------------------------------------------------
service_desu_object_cursor:				dq	0
							dq	0
							dq	12
							dq	19
							dq	service_desu_object_cursor.data
.extra:							dq	service_desu_object_cursor.end - service_desu_object_cursor.data
							dq	SERVICE_DESU_OBJECT_FLAG_pointer | SERVICE_DESU_OBJECT_FLAG_flush | SERVICE_DESU_OBJECT_FLAG_visible
							dq	STATIC_EMPTY	; obiekt kursora nie posiada identyfikatora
.data:							incbin	"kernel/service/desu/gfx/cursor.data"
.end:
