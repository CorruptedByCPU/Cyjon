;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_VFS_FILE_TYPE_fifo				equ	1 << 0
KERNEL_VFS_FILE_TYPE_character_device			equ	1 << 1
KERNEL_VFS_FILE_TYPE_directory				equ	1 << 2
KERNEL_VFS_FILE_TYPE_block_device			equ	1 << 3
KERNEL_VFS_FILE_TYPE_regular_file			equ	1 << 4
KERNEL_VFS_FILE_TYPE_symbolic_link			equ	1 << 5
KERNEL_VFS_FILE_TYPE_socket				equ	1 << 6
KERNEL_VFS_FILE_TYPE_volume				equ	1 << 7

KERNEL_VFS_FILE_MODE_suid				equ	0000100000000000b
KERNEL_VFS_FILE_MODE_sgid				equ	0000010000000000b
KERNEL_VFS_FILE_MODE_sticky				equ	0000001000000000b
KERNEL_VFS_FILE_MODE_USER_read				equ	0000000100000000b
KERNEL_VFS_FILE_MODE_USER_write				equ	0000000010000000b
KERNEL_VFS_FILE_MODE_USER_execute_or_traverse		equ	0000000001000000b
KERNEL_VFS_FILE_MODE_USER_full_control			equ	0000000111000000b
KERNEL_VFS_FILE_MODE_GROUP_read				equ	0000000000100000b
KERNEL_VFS_FILE_MODE_GROUP_write			equ	0000000000010000b
KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse		equ	0000000000001000b
KERNEL_VFS_FILE_MODE_GROUP_full_control			equ	0000000000111000b
KERNEL_VFS_FILE_MODE_OTHER_read				equ	0000000000000100b
KERNEL_VFS_FILE_MODE_OTHER_write			equ	0000000000000010b
KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse		equ	0000000000000001b
KERNEL_VFS_FILE_MODE_OTHER_full_control			equ	0000000000000111b

struc	KERNEL_VFS_STRUCTURE_META
	.data						resb	0x10
	.SIZE:
endstruc

; struktura supła w drzewie katalogu głównego
struc	KERNEL_VFS_STRUCTURE_KNOT
	.data						resb	8
	.size						resb	8
	.type						resb	1
	.length						resb	1
	.mode						resb	2
	.flags						resb	2
	.time_modified					resb	8
	.name						resb	255
	.meta:						resb	KERNEL_VFS_STRUCTURE_META.SIZE
	.SIZE:
endstruc
