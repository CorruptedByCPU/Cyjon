;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

	;----------------------------------------------------------------------
	; variables, structures, definitions
	;----------------------------------------------------------------------
	%ifndef	LIB_ELF
		%include	"./elf.inc"
	%endif

; we are using Position Independed Code
default	rel

; 64 bit code
[bits 64]

; information for linker
section .text

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to beginning of file
; out:
;	CF - if its not an ELF64 file
lib_elf_identify:
	; by default
	clc

	; file contains ELF header?
	cmp	dword [rdi + LIB_ELF_STRUCTURE.magic_number],	0x464C457F
	je	.done	; yes

	; undefinied file
	stc

.done:
	; return from routine
	ret
