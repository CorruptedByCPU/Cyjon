;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_VFS_FILE_TYPE_regular_file			equ	1 << 0
KERNEL_VFS_FILE_TYPE_directory				equ	1 << 1
KERNEL_VFS_FILE_TYPE_symbolic_link			equ	1 << 2
KERNEL_VFS_FILE_TYPE_character_device			equ	1 << 3
KERNEL_VFS_FILE_TYPE_block_device			equ	1 << 4
KERNEL_VFS_FILE_TYPE_fifo				equ	1 << 5
KERNEL_VFS_FILE_TYPE_socket				equ	1 << 6
