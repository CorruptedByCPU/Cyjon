;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

%MACRO	macro_library	1
	; odłóż na stos adres procedury powrotnej
	push	rbp
	mov	rbp,	%%exit
	xchg	rbp,	qword [rsp]

	; odłóż na stos adres biblioteki
	push	rbp	; zachowaj oryginalny rejestr
	mov	rbp,	LIBRARY_BASE_address + %1
	mov	rbp,	qword [rbp]
	xchg	rbp,	qword [rsp]

	; wykonaj skok do biblioteki
	ret

%%exit:
%ENDMACRO
