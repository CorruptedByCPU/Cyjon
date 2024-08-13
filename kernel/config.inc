;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%define	KERNEL_name			"Cyjon"
%define	KERNEL_version			"0"
%define	KERNEL_revision			"2167"
%define	KERNEL_architecture		"x86_64"
%define	KERNEL_language			"Assembly"

%define	KERNEL_BASE_address		0xFFFFFFFF80000000	; higher half

%define	KERNEL_STACK_page		2
%define	KERNEL_STACK_address		-(KERNEL_STACK_page << STD_SHIFT_PAGE)	; minimal size
%define	KERNEL_STACK_pointer		0xFFFFFFFFFFFFF000

%ifndef	KERNEL_GDT
	%include		"./kernel/gdt.inc"
%endif

%ifndef	KERNEL_TSS
	%include		"./kernel/tss.inc"
%endif

struc	KERNEL
	; variables of Kernel management functions
	.cpu_count			resq	1

	; variables of Input devices
	.device_mouse_status		resb	1
	.device_mouse_x			resw	1
	.device_mouse_y			resw	1
	.device_keyboard		resw	8	; cache size of 8 keys

	; variables of Framebuffer management functions
	.framebuffer_base_address	resq	1
	.framebuffer_width_pixel	resw	1
	.framebuffer_height_pixel	resw	1
	.framebuffer_pitch_byte		resd	1
	.framebuffer_pid		resq	1

	; variables of GDT management functions
	.gdt_header			resb	KERNEL_STRUCTURE_GDT_HEADER.SIZE

; variables of I/O APIC management functions
.io_apic_base_address		resq	1

; variables of IPC management functions
.ipc_base_address		resq	1
.ipc_semaphore			resb	1

; variables of LAPIC management functions
.lapic_base_address		resq	1
.lapic_last_id			resd	1

; variables of Library management functions
.library_base_address		resq	1
.library_memory_map_address	resq	1

; pointers of Log management functions
.log				resq	1

	; variables of Memory management functions
	.memory_base_address		resq	1
.memory_semaphore		resb	1
; pointers of Memory management functions
.memory_release			resq	1

	; variables of Page management functions
.page_base_address		resq	1
	.page_total			resq	1
	.page_available			resq	1
	.page_limit			resq	1
.page_array			resq	1
; pointers of Page management functions
.page_deconstruction		resq	1

; variables of Storage management functions
.storage_base_address		resq	1
.storage_root_id		resb	1
.storage_semaphore		resb	1

; variables of Stream management functions
.stream_base_address		resq	1
.stream_semaphore		resb	1
; pointers of Stream management functions
.stream_release			resq	1

; variables of Task management functions
.task_queue_address		resq	1
.task_ap_address		resq	1
.task_queue_semaphore		resb	1
.task_id			resq	1
.task_count			resq	1
.task_cpu_semaphore		resb	1

	; variables of Time management functions
.time_rdtsc			resq	1
	.time_rtc			resq	1

	; variables of TSS management functions
	.tss_table			resb	KERNEL_STRUCTURE_TSS.SIZE

	; length of this structure in Bytes
	.SIZE:
endstruc
