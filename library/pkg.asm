;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	rcx - size in Bytes
;	rsi - pointer to begining of data
; out:
;	CF - if TRUE
lib_pkg_check:


	; return from routine
	ret