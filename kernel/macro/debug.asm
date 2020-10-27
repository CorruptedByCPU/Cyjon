;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

%macro	macro_debug	1
%ifdef	DEBUG
	jmp	%%skip

	db	" [", %1, "] "

%%skip:
%endif
%endmacro
