;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

driver_fs_fat32_entry_table:	dq	driver_fs_fat32_read	; read procedure
				dq	STATIC_EMPTY	; write procedure

;===============================================================================
driver_fs_fat32_read:
	; powrót z procedury
	ret
