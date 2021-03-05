;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
zero_storage:
	; wczytaj kod jądra systemu
	mov	ah,	0x42
	mov	si,	zero_table_disk_address_packet
	int	0x13
