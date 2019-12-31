;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"	; globalne
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"	; lokalne
	;-----------------------------------------------------------------------

; 32 bitowy kod inicjalizacyjny jądra systemu
[BITS 32]

; położenie kodu jądra systemu w pamięci fizycznej
[ORG KERNEL_BASE_address]

init:
	;-----------------------------------------------------------------------
	; Init - inicjalizacja środowiska pracy jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init.asm"

; wyrównaj pozycję kodu jądra systemu do pełnej strony
align	KERNEL_PAGE_SIZE_byte,	db	STATIC_NOTHING
kernel:
	; przejdź do powłoki systemu
	; jmp	service_shell

	; przejdź do usługi HTTP
	jmp	service_http

	;-----------------------------------------------------------------------
	; procedury, makra, dane, biblioteki, usługi - wszystko co niezbędne
	; do prawidłowej pracy jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/macro/close.asm"
	%include	"kernel/macro/apic.asm"
	%include	"kernel/macro/debug.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/ipc.asm"
	%include	"kernel/panic.asm"
	%include	"kernel/page.asm"
	%include	"kernel/memory.asm"
	%include	"kernel/video.asm"
	%include	"kernel/apic.asm"
	%include	"kernel/io_apic.asm"
	%include	"kernel/data.asm"
	%include	"kernel/idt.asm"
	%include	"kernel/task.asm"
	%include	"kernel/thread.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/driver/rtc.asm"
	%include	"kernel/driver/ps2.asm"
	%include	"kernel/driver/pci.asm"
	%include	"kernel/driver/network/i82540em.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/service/tresher.asm"
	%include	"kernel/service/shell.asm"
	%include	"kernel/service/http.asm"
	%include	"kernel/service/tx.asm"
	%include	"kernel/service/network.asm"
	;-----------------------------------------------------------------------
	%include	"library/input.asm"
	%include	"library/page_align_up.asm"
	%include	"library/page_from_size.asm"
	%include	"library/string_compare.asm"
	%include	"library/string_cut.asm"
	%include	"library/string_digits.asm"
	%include	"library/string_to_integer.asm"
	%include	"library/string_trim.asm"
	%include	"library/string_word_next.asm"
	;-----------------------------------------------------------------------

kernel_end:
