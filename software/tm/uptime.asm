;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - uptime
tm_uptime:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8

	; rax - uptime

	; zamień wartość "uptime" na sekundy
	mov	ecx,	1024
	xor	edx,	edx
	div	rcx

	; system liczbowy: dziesiętny
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal

	; ciąg znaków reprezentujących wartość
	mov	rdi,	tm_string_value_format

	; wyczyść flagi
	xor	r8,	r8

	;-----------------------------------------------------------------------

	; zamień uptime na ilość dni
	mov	ecx,	60*60*24	; 86400 sekund
	xor	edx,	edx
	div	rcx

	; format: _D.HHd
	mov	ecx,	0x02

	; zachowaj resztę z dzielenia (godziny)
	push	rdx

	; domyśny prefix
	mov	edx,	STATIC_SCANCODE_SPACE

	; brak dni?
	test	rax,	rax
	jz	.no_days	; tak

	; zachowaj ilość dni
	push	rax

	; ilość dni mniejsza od 10?
	cmp	rax,	10
	jb	.day_overflow	; nie

	; format: _DDDDd
	mov	ecx,	TM_TABLE_CELL_time_width - 0x01

.day_overflow:
	; konwertuj wartość na ciąg
	call	library_integer_to_string

	; wyświetl
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; przywróć ilość wyświetlonych dni
	pop	rax

	; domyślny format "_D.HHd"
	mov	dl,	"."

	; wyświetlamy hodziny?
	cmp	rax,	10
	jb	.days	; tak

	; zmień na format "_DDDDd"
	mov	dl,	"d"

.days:
	; wyświetl typ
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x01	; jeden znak
	int	KERNEL_SERVICE

	; ustaw flagę, wyświetlono godziny
	mov	r8,	TM_UPTIME_FLAG_hour

.no_days:
	; przywróć resztę z dzielenia
	pop	rax

	; koniec przetwarzania?
	cmp	dl,	"d"
	je	.end	; tak

	;-----------------------------------------------------------------------

	; zamień uptime na ilość godzin
	mov	ecx,	60*60	; 3600 sekund
	xor	edx,	edx
	div	rcx

	; format: _H:MMh
	mov	ecx,	0x02

	; zachowaj resztę z dzielenia (minuty)
	push	rdx

	; domyśny prefix
	mov	edx,	STATIC_SCANCODE_DIGIT_0

	; brak godzin?
	test	rax,	rax
	jz	.no_hours	; tak

	; zachowaj ilość godzin
	push	rax

	; wyświetlono dni?
	test	r8,	TM_UPTIME_FLAG_day
	jnz	.hours_only	; tak

	; prefix dla formatu bez dni
	mov	dl,	STATIC_SCANCODE_SPACE

.hours_only:
	; ilość godzin większa od 10?
	cmp	rax,	10	; 10 godzin
	jb	.hour_overflow	; nie

	; format: ___HHh
	mov	ecx,	TM_TABLE_CELL_time_width - 0x01

.hour_overflow:
	; konwertuj wartość na ciąg
	call	library_integer_to_string

	; wyświetl
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; przywróć ilość wyświetlonych godzin
	pop	rax

	; domyślny format "_H:MMh"
	mov	dl,	":"

	; wyświetlamy minuty?
	cmp	rax,	10
	jb	.hours	; tak

	; zmień na format "___HHh"
	mov	dl,	"h"

.hours:
	; wyświetl typ
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x01	; jeden znak
	int	KERNEL_SERVICE

	; ustaw flagę, wyświetlono godziny
	mov	r8,	TM_UPTIME_FLAG_hour

.no_hours:
	; przywróć resztę z dzielenia
	pop	rax

	; koniec przetwarzania?
	cmp	dl,	"h"
	je	.end	; tak

	;-----------------------------------------------------------------------

	; zamień uptime na ilość minut
	mov	ecx,	60	; 60 sekund
	xor	edx,	edx
	div	rcx

	; format: _M:SSm lub _H:MMh
	mov	ecx,	0x02

	; zachowaj resztę z dzielenia (sekundy)
	push	rdx

	; domyśny prefix
	mov	edx,	STATIC_SCANCODE_DIGIT_0

	; brak minut?
	test	rax,	rax
	jz	.no_minutes	; tak

	; zachowaj ilość minut
	push	rax

	; wyświetlono godziny?
	test	r8,	TM_UPTIME_FLAG_hour
	jnz	.minutes_only	; tak

	; prefix dla formatu bez godzin
	mov	dl,	STATIC_SCANCODE_SPACE

.minutes_only:
	; ilość minut mniejsza od 10?
	cmp	rax,	10	; 10 minut
	jb	.minutes_overflow	; nie

	; format: ___MMm
	mov	ecx,	TM_TABLE_CELL_time_width - 0x01

.minutes_overflow:
	; konwertuj wartość na ciąg
	call	library_integer_to_string

	; wyświetl
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; przywróć ilość wyświetlonych minut
	pop	rax

	; domyślny format "_M:SSm"
	mov	dl,	":"

	; wyświetlamy sekundy?
	cmp	rax,	10
	jb	.minutes	; tak

	; zmień na format "___MMm"
	mov	dl,	"m"

.minutes:
	; wyświetl typ
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x01	; jeden znak
	int	KERNEL_SERVICE

	; ustaw flagę, wyświetlono minuty
	mov	r8,	TM_UPTIME_FLAG_minute

.no_minutes:
	; przywróć resztę z dzielenia
	pop	rax

	; koniec przetwarzania?
	cmp	dl,	"m"
	je	.end	; tak

	;-----------------------------------------------------------------------

	; format: _M:SSm
	mov	ecx,	0x02

	; domyśny prefix
	mov	edx,	STATIC_SCANCODE_DIGIT_0

	; wyświetlono minuty?
	test	r8,	TM_UPTIME_FLAG_minute
	jnz	.second_overflow	; tak

	; format: ___SSs
	mov	ecx,	TM_TABLE_CELL_time_width - 0x01

	; prefix dla formatu bez minut
	mov	dl,	STATIC_SCANCODE_SPACE

.second_overflow:
	; konwertuj wartość na ciąg
	call	library_integer_to_string

	; wyświetl
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rsi,	rdi
	int	KERNEL_SERVICE

	; domyślny format "___SSs"
	mov	dl,	"s"

	; wyświetlono minuty?
	test	r8,	TM_UPTIME_FLAG_minute
	jz	.seconds_only	; nie

	; zmień na format "_M:SSm"
	mov	dl,	"m"

.seconds_only:
	; wyświetl typ
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x01	; jeden znak
	int	KERNEL_SERVICE

.end:
	; przywróć oryginalne rejestry
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
