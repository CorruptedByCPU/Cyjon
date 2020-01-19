;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
kernel_service:
	; zachowaj oryginalny rejestr
	push	rax

	; usługa związana z procesem?
	cmp	al,	KERNEL_SERVICE_PROCESS
	je	.process	; tak

	; obsługa przestrzeni konsoli?
	cmp	al,	KERNEL_SERVICE_VIDEO
	je	.video	 ; tak

	; obsługa klawiatury?
	cmp	al,	KERNEL_SERVICE_KEYBOARD
	je	.keyboard	; tak

.error:
	; flaga, błąd
	stc

.end:
	; pobierz aktualne flagi procesora
	pushf
	pop	rax

	; usuń flagi, które nie biorą udziału w komunikacji
	and	ax,	KERNEL_TASK_EFLAGS_cf | KERNEL_TASK_EFLAGS_zf

	; zwróć flagi do procesu
	and	word [rsp + KERNEL_STRUCTURE_TASK_IRETQ.eflags + STATIC_QWORD_SIZE_byte],	~KERNEL_TASK_EFLAGS_cf
	and	word [rsp + KERNEL_STRUCTURE_TASK_IRETQ.eflags + STATIC_QWORD_SIZE_byte],	~KERNEL_TASK_EFLAGS_zf
	or	word [rsp + KERNEL_STRUCTURE_TASK_IRETQ.eflags + STATIC_QWORD_SIZE_byte],	ax

	; przywróć oryginalny rejestr
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

;===============================================================================
.process:
	; zakończ pracę procesu?
	cmp	ax,	KERNEL_SERVICE_PROCESS_exit
	je	kernel_task_kill	; tak

	; uruchomić nowy proces?
	cmp	ax,	KERNEL_SERVICE_PROCESS_run
	je	.process_run	; tak

	; koniec obsługi podprocedury
	jmp	kernel_service.error

;-------------------------------------------------------------------------------
.process_run:
	; rozwiąż ścieżkę do programu
	call	kernel_vfs_path_resolve
	jc	kernel_service.end	; błąd, niepoprawna ścieżka

	; odszukaj program w danym katalogu
	call	kernel_vfs_file_find
	jc	kernel_service.end	; błąd, pliku nie znaleziono

	; uruchom program
	call	kernel_exec

	; koniec obsługi opcji
	jmp	kernel_service.end

;===============================================================================
.video:
	; wyświetlić ciąg znaków w konsoli?
	cmp	ax,	KERNEL_SERVICE_VIDEO_string
	je	.video_string	; tak

	; pobrać pozycję wirtualnego kursora?
	cmp	ax,	KERNEL_SERVICE_VIDEO_cursor
	je	.video_cursor	; tak

	; wyświetlić znak N razy?
	cmp	ax,	KERNEL_SERVICE_VIDEO_char
	je	.video_char	; nie

	; wyczyścić przestrzeń konsoli?
	cmp	ax,	KERNEL_SERVICE_VIDEO_clean
	je	.video_clean	; nie

	; koniec obsługi podprocedury
	jmp	kernel_service.error

;-------------------------------------------------------------------------------
.video_string:
	; wyświetl ciąg w konsoli
	call	kernel_video_string

	; koniec obsługi podprocedury
	jmp	kernel_service.end

;-------------------------------------------------------------------------------
.video_cursor:
	; zwróć informacje o pozycji wirtualnego kursora
	mov	rbx,	qword [kernel_video_cursor]

	; koniec obsługi podprocedury
	jmp	kernel_service.end

;-------------------------------------------------------------------------------
.video_char:
	; wyświetl znak N razy
	mov	ax,	dx
	call	kernel_video_char

	; koniec obsługi podprocedury
	jmp	kernel_service.end

;-------------------------------------------------------------------------------
.video_clean:
	; wyczyść przestrzeń konsoli
	call	kernel_video_drain

	; koniec obsługi podprocedury
	jmp	kernel_service.end

;===============================================================================
.keyboard:
	; pobrać kod klawisza z bufora?
	cmp	ax,	KERNEL_SERVICE_KEYBOARD_key
	jne	kernel_service.error	; koniec obsługi podprocedury

	; pobierz kod klawisza z bufora
	call	driver_ps2_keyboard_read

	; zwróć kod ASCII znaku do procesu
	mov	word [rsp],	ax

	; koniec obsługi podprocedury
	jmp	kernel_service.end
