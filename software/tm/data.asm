;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

align	STATIC_QWORD_SIZE_byte,			db	STATIC_EMPTY
tm_stream_meta:
	times	KERNEL_STREAM_META_SIZE_byte	db	STATIC_EMPTY

tm_string_init					db	STATIC_ASCII_SEQUENCE_CURSOR_DISABLE, STATIC_ASCII_SEQUENCE_CLEAR
tm_string_init_end:

tm_string_uptime				db	STATIC_ASCII_SEQUENCE_COLOR_DEFAULT, "up"
tm_string_uptime_end:
tm_string_uptime_days				db	" days, "
tm_string_uptime_days_end:
tm_string_tasks					db	"^[t1;0;1]Tasks: "
tm_string_tasks_end:
tm_string_tasks_total				db	" total, "
tm_string_tasks_total_end:
tm_string_tasks_running				db	" running, "
tm_string_tasks_running_end:
tm_string_tasks_sleeping			db	" sleeping"
tm_string_tasks_sleeping_end:
tm_string_memory				db	"^[t1;0;2]MiB Mem: "
tm_string_memory_end:
tm_string_header_position_and_color		db	"^[t1;0;4]^[c70]"
tm_string_header_position_and_color_end:
tm_string_header				db	"  PID %CPU %Mem Time+ Command"
tm_string_header_end:

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
tm_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY
