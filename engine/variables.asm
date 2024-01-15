;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

text_arrow_right			db	"-> ", VARIABLE_ASCII_CODE_TERMINATOR
text_caution				db	"::", VARIABLE_ASCII_CODE_TERMINATOR
text_colon				db	":", VARIABLE_ASCII_CODE_TERMINATOR
text_sub				db	"   ", VARIABLE_ASCII_CODE_TERMINATOR
text_subsub				db	"    ",	VARIABLE_ASCII_CODE_TERMINATOR
text_paragraph				db	VARIABLE_ASCII_CODE_RETURN
text_close				db	"]", VARIABLE_ASCII_CODE_TERMINATOR
text_open				db	"[", VARIABLE_ASCII_CODE_TERMINATOR

text_kib				db	" KiB", VARIABLE_ASCII_CODE_TERMINATOR
text_mib				db	" MiB", VARIABLE_ASCII_CODE_TERMINATOR
text_gib				db	" GiB", VARIABLE_ASCII_CODE_TERMINATOR
text_tib				db	" TiB", VARIABLE_ASCII_CODE_TERMINATOR

text_irq				db	", IRQ ", VARIABLE_ASCII_CODE_TERMINATOR

text_return				db	VARIABLE_ASCII_CODE_RETURN

; Multiboot Information Structure
struc	MIS
	.flags		resd	1
	.ignore		resb	40
	.mmap_length	resd	1
	.mmap_addr	resd	1
endstruc

; struktura tablicy mapy pamięci oprogramowania GRUB
struc	MMAP_STRUCTURE
	.record_size	resd	1
	.base_address	resq	1
	.memory_amount	resq	1
	.flags		resd	1
endstruc

variable_idt_structure:
	.limit				dw	VARIABLE_MEMORY_PAGE_SIZE	; rozmiar tablicy / do 512 rekordów
	.address			dq	VARIABLE_EMPTY

; ilość 0.001 sekundy upłyniętych od inicjalizacji jądra systemu
variable_system_microtime		dq	VARIABLE_EMPTY
variable_system_uptime			dq	VARIABLE_EMPTY
variable_cursor_blink			db	VARIABLE_FALSE
