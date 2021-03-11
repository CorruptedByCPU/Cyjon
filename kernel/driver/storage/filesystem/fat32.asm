;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

filesystem_fat32_entry_table:	dq	driver_ide_read	; read procedure
				dq	STATIC_EMPTY	; write procedure
