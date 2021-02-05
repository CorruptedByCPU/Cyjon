;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/tm/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
tm:
	; inicjalizuj środowisko pracy menedżera zadań
	%include	"software/tm/init.asm"

.check:
	; pobierz informacje o strumieniu wyjścia
	call	tm_stream_info

.loop:
	; ustaw kursor na pozycję "uptime"
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_uptime_position_and_color_end - tm_string_uptime_position_and_color
	mov	rsi,	tm_string_uptime_position_and_color
	int	KERNEL_SERVICE

	; pobierz aktualne zegary systemu
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; wyświetl uptime systemu
	call	tm_uptime

	; wyświetl wykorzystanie pamięci RAM
	call	tm_ram

	; wyświetl ilość i listę aktywnych procesów
	call	tm_task

	; koleja aktualizacja stanu za 1 sekundę
	add	rax,	1024
	mov	qword [tm_microtime],	rax

.event:
	; pobierz microtime systemu
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; odczekano 1 sekundę?
	cmp	rax,	qword [tm_microtime]
	jnb	.check	; tak

	;-----------------------------------------------------------------------
	; pobierz wiadomość
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	tm_ipc_data
	int	KERNEL_SERVICE
	jc	.no_event	; brak wiadomości

	; komunikat typu: klawiatura?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	jne	.no_event	; nie, zignoruj

	; naciśnięto klawisz "q"?
	cmp	word [rdi + KERNEL_IPC_STRUCTURE.data],	"q"
	je	.end	; tak, zakończ działanie procesu

	; włącz tryb debugowania (Bochs)
	jmp	.loop

.no_event:
	; zwolnij pozostały czas procesora
	mov	ax,	KERNEL_SERVICE_PROCESS_sleep
	xor	ecx,	ecx	; brak oczekiwania w czasie
	int	KERNEL_SERVICE

	; powrót do głównej pętli
	jmp	.event

.end:
	; przesuń wirtualny kursor na koniec przestrzeni ekranu tekstowego
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_end_of_work_end - tm_string_end_of_work
	mov	rsi,	tm_string_end_of_work
	int	KERNEL_SERVICE

	; zakończ proces
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: tm"

	;-----------------------------------------------------------------------
	%include	"software/tm/data.asm"
	%include	"software/tm/static.asm"
	%include	"software/tm/stream.asm"
	%include	"software/tm/ram.asm"
	%include	"software/tm/uptime.asm"
	%include	"software/tm/task.asm"
	%include	"software/tm/percent.asm"
	;-----------------------------------------------------------------------
