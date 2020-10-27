;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

%macro	macro_apic_id_get	0
	; pobierz ID procesora logicznego
	mov	rax,	qword [kernel_apic_base_address]
	mov	dword [rax + KERNEL_APIC_TP_register],	STATIC_EMPTY
	mov	eax,	dword [rax + KERNEL_APIC_ID_register]
	shr	eax,	24	; przesuń bity 24..31 do 0..7
%endmacro
