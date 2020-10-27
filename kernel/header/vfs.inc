;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_VFS_FILE_TYPE_socket				equ	01000000b
KERNEL_VFS_FILE_TYPE_symbolic_link			equ	00100000b
KERNEL_VFS_FILE_TYPE_regular_file			equ	00010000b
KERNEL_VFS_FILE_TYPE_block_device			equ	00001000b
KERNEL_VFS_FILE_TYPE_directory				equ	00000100b
KERNEL_VFS_FILE_TYPE_character_device			equ	00000010b
KERNEL_VFS_FILE_TYPE_fifo				equ	00000001b
