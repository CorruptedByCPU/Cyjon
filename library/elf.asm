;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to beginning of file
; out:
;	CF - if its not an ELF64 file
lib_elf_check:
	; file contains ELF header?
	cmp	dword [rdi + LIB_ELF_STRUCTURE.magic_number],	0x464C457F
	jne	.error	; no

	; we do not need to know anything else, right now
	; the ecosystem is closed, so we don't expect programs from outside

	; test passed
	clc

	; end of procedure
	jmp	.end

.error:
	; test failed
	stc

.end:
	; return from routine
	ret