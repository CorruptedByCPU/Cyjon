;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; in:
;	rcx - length in Bytes
;	rsi - pointer to beginning of file
; out:
;	ZF - if valid VFS file
kernel_vfs_identify:
	; preserve original register
	push	rcx

	; offset of magic value
	shr	rcx,	STD_SHIFT_4
	dec	rcx

	; at end of file, magic value exist?
	cmp	dword [rsi + rcx * STD_SIZE_DWORD_byte],	LIB_VFS_magic

	; restore original register
	pop	rcx

	; return from routine
	ret
