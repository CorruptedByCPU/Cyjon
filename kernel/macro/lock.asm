;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

%macro	macro_lock	2
	push	rax

.1:	; zamknij dostęp do %1
	mov	al,	STATIC_TRUE
	lock	xchg	byte [%1 + %2],	al
	test	al,	al
	jz	.1	; spróbuj raz jeszcze

	pop	rax
%endmacro
