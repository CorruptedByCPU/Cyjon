;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"
	%include	"kernel/config.asm"
	;-----------------------------------------------------------------------

; 64 bitowy kod programu
[BITS 64]

; adresowanie względne
[DEFAULT REL]

; położenie kodu programu w pamięci logicznej
[ORG SOFTWARE_base_address]

;===============================================================================
init:
	; wyświetl logo
	mov	ax,	KERNEL_SERVICE_VIDEO_string
	mov	ecx,	init_string_logo_end - init_string_logo
	mov	rsi,	init_string_logo
	int	KERNEL_SERVICE

	; uruchom powłokę systemu
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	ecx,	init_program_shell_end - init_program_shell
	xor	edx,	edx	; bez argumentów
	mov	rsi,	init_program_shell
	int	KERNEL_SERVICE

	; debug
	jmp	$

	; czekaj na zakończenie procesu
	mov	ax,	KERNEL_SERVICE_PROCESS_pid

.wait_for_shell:
	; proces zakończył swoją pracę
	int	KERNEL_SERVICE
	jnc	.wait_for_shell	; nie

	; wyświetl znak zachęty od nowej linii
	jmp	init

	;=======================================================================
	%include	"software/init/data.asm"
	;=======================================================================
