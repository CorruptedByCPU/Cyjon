;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
tm_uptime:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9

	; ustaw kursor na pozycję "uptime"
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_uptime_position_and_color_end - tm_string_uptime_position_and_color
	mov	rsi,	tm_string_uptime_position_and_color
	int	KERNEL_SERVICE

	; pobierz aktualne zegary systemu
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; r8 - uptime

	; zamień wartość "uptime" na sekundy
	mov	rax,	r8
	mov	ecx,	1024
	xor	edx,	edx
	div	rcx

	; wyświetl wartość w sekundach
	mov	ecx,	60
	call	.format
	jnz	.minute	; wartość większa od 59 sekund

	; zakończ informacją o typie
	mov	ecx,	tm_string_uptime_seconds_end - tm_string_uptime_seconds
	mov	rsi,	tm_string_uptime_seconds
	int	KERNEL_SERVICE

	; koniec
	jmp	.end

.minute:
	; wyświetl wartość w minutach
	call	.format
	jnz	.hour	; wartość większa od 59 minut

	; zakończ informacją o typie
	mov	ecx,	tm_string_uptime_minutes_end - tm_string_uptime_minutes
	mov	rsi,	tm_string_uptime_minutes
	int	KERNEL_SERVICE

	; koniec
	jmp	.end

.hour:
	; wyświetl wartość w godzinach
	mov	ecx,	24
	call	.format
	jnz	.days	; wartość większa od 23 godzin

	; zakończ informacją o typie
	mov	ecx,	tm_string_uptime_hours_end - tm_string_uptime_hours
	mov	rsi,	tm_string_uptime_hours
	int	KERNEL_SERVICE

	; koniec
	jmp	.end

.days:
	; wyświetl wartość w dniach
	call	.show

	; zakończ informacją o typie
	mov	ecx,	tm_string_uptime_days_end - tm_string_uptime_days
	mov	rsi,	tm_string_uptime_days
	int	KERNEL_SERVICE

.end:
	; przywróć oryginalne rejestry
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
.format:
	; zamień uptime na następną wartość
	xor	edx,	edx
	div	rcx

	; system działa mniej sugerowana wartość?
	test	rax,	rax
	jnz	.format_end	; nie

	; wyświetl wartość
	mov	rax,	rdx
	call	.show

.format_end:
	; powrót z podprocedury
	ret

;-------------------------------------------------------------------------------
.show:
	; zamień wartość na ciąg
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx
	mov	rdi,	tm_string_value_format
	call	library_integer_to_string

	; wyświetl
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; powrót z podprocedury
	ret
