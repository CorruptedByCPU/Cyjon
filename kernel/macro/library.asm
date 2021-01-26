;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

%MACRO	macro_library	1
	; zachowaj wartość procesu
	push	rbp

	; odłóż na stos adres procedury docelowej
	mov	rbp,	LIBRARY_base_address + %1
	call	qword [rbp]	; wykonaj skok do biblioteki

	; przywróć wartość procesu
	pop	rbp
%ENDMACRO
