;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_DAEMON_GARBAGE_COLLECTOR_NAME_COUNT	equ	17
variable_daemon_garbage_collector_name		db	"garbage collector"

; 64 Bitowy kod programu
[BITS 64]

daemon_garbage_collector:
	; szukaj procesu gotowego do zamknięcia
	mov	bx,	STATIC_SERPENTINE_RECORD_FLAG_USED + STATIC_SERPENTINE_RECORD_FLAG_CLOSED

	call	cyjon_multitasking_serpentine_find_record

	; pobierz adres tablicy PML4 procesu do zamknięcia
	mov	rbx,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.CR3]

	; zapamiętaj adres tablicy PML4 procesu
	push	rbx

	; zmniejsz ilość procesów przechowywanych w tablicy
	dec	qword [variable_multitasking_serpentine_record_counter]

	cmp	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.ARGS],	VARIABLE_EMPTY
	je	.no_args

	; zwolnij przestrzeń pod argumenty
	push	rdi

	mov	rdi,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.ARGS]
	call	cyjon_page_release

	; zmniejszono rozmiar buforów
	dec	qword [variable_binary_memory_map_cached]

	pop	rdi

.no_args:
	; czy proces zajmował na wyłączność dostęp do przestrzeni pamięci ekranu?
	bt	qword [rdi],	STATIC_SERPENTINE_RECORD_BIT_DESKTOP
	jnc	.no_desktop

	; zwolnij dostęp
	mov	byte [variable_screen_video_user_semaphore],	VARIABLE_FALSE

.no_desktop:
	; wyczyść rekord w tablicy
	xor	al,	al
	mov	rcx,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE
	rep	stosb

	; zwolnij pamięć zajętą przez proces
	mov	rdi,	rbx	; załaduj adres tablicy PML4 procesu
	add	rdi,	255 * VARIABLE_QWORD_SIZE	; rozpocznij zwalnianie przestrzeni od rekordu stosu kontekstu procesu
	mov	rbx,	4	; ustaw poziom tablicy przetwarzanej
	mov	rcx,	257	; ile pozostało rekordów w tablicy PML4 do zwolnienia
	call	cyjon_page_release_area.loop

	; przywróć adres tablicy PML4 procesu
	pop	rdi

	; zwolnij przestrzeń spod tablicy PML4 procesu
	call	cyjon_page_release

	; mniejszono rozmiar stronicowania
	dec	qword [variable_binary_memory_map_paged]

	; koniec zadań, przekaż resztę cykli
	hlt

	; rozpocznij od nowa
	jmp	daemon_garbage_collector
