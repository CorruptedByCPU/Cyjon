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
	%include	"kernel/macro/apic.asm"
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

; wyrównaj pozycję kodu do pełnej strony
align	KERNEL_PAGE_SIZE_byte,	db	STATIC_NOTHING

clean:
	; debug
	cli
	int	0x00

	; ; rozmiar przestrzeni inicjalizacyjnej
	; mov	ecx,	clean - $$
	; call	library_page_from_size	; w stronach
	;
	; ; zwolnij
	; mov	rdi,	KERNEL_BASE_address
	; call	kernel_memory_release

kernel:
	; uruchom program inicjalizujący środowisko użytkownika
	mov	ecx,	kernel_init_exec_end - kernel_init_exec
	mov	rsi,	kernel_init_exec
	call	kernel_vfs_path_resolve
	jc	.error	; błędna ścieżka
	call	kernel_vfs_file_find
	jc	.error	; nie znaleziono pliku
	call	kernel_exec
	jnc	.end	; nie udało się uruchomić procesu

.error:
	; wyświetl kod błędu
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx	; brak wypełnienia
	call	kernel_video_number

.end:
	; zatrzymaj dalsze wykonywanie kodu jądra systemu
	jmp	$

	;-----------------------------------------------------------------------
	; procedury, makra, dane, biblioteki, usługi - wszystko co niezbędne
	; do prawidłowej pracy jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/macro/close.asm"
	%include	"kernel/macro/debug.asm"
	%include	"kernel/macro/copy.asm"
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
;	%include	"kernel/thread.asm"
	%include	"kernel/vfs.asm"
	%include	"kernel/exec.asm"
	%include	"kernel/service.asm"
	%include	"kernel/debug.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/font/canele.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/driver/rtc.asm"
	%include	"kernel/driver/ps2.asm"
	%include	"kernel/driver/pci.asm"
	%include	"kernel/driver/network/i82540em.asm"
	%include	"kernel/driver/storage/ide.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/service/tresher.asm"
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
