;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; następny wolny numer PID procesu
variable_multitasking_pid_value_next				dq	VARIABLE_EMPTY

variable_multitasking_serpentine_blocked			db	VARIABLE_EMPTY
variable_multitasking_serpentine_start_address			dq	VARIABLE_EMPTY
variable_multitasking_serpentine_record_active_address		dq	VARIABLE_EMPTY
variable_multitasking_serpentine_record_counter			dq	VARIABLE_EMPTY
variable_multitasking_serpentine_record_counter_left_in_page	dq	VARIABLE_EMPTY
variable_multitasking_serpentine_record_counter_handle		dq	VARIABLE_EMPTY

; 64 Bitowy kod programu
[BITS 64]

;===============================================================================
; procedura tworzy i dodaje jądro systemu do tablicy procesów uruchomionych
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
multitasking:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; przygotuj czystą przestrzeń pod serpentynę procesów
	call	cyjon_page_allocate
	cmp	rdi,	VARIABLE_EMPTY
	jne	.page0_ok

	; błąd krytyczny
	mov	rsi,	text_kernel_panic_sheduler_no_memory
	jmp	cyjon_screen_kernel_panic

.page0_ok:
	; zwiększono rozmiar buforów
	inc	qword [variable_binary_memory_map_cached]

	call	cyjon_page_clear

	; zapamiętaj adres serpentyny
	mov	qword [variable_multitasking_serpentine_start_address],	rdi

	; utwórz pierwszy rekord w serpentynie procesów, czyli jądro systemu ---

	; bezpośredni adres do aktywnego rekordu
	mov	qword [variable_multitasking_serpentine_record_active_address],	rdi

	; załaduj do rekordu jądra systemu w serpentynie, numer PID
	mov	rax,	qword [variable_multitasking_pid_value_next]
	stosq

	; załaduj do rekordu adres tablicy PML4 jądra systemu
	mov	rax,	cr3
	stosq

	; przy pierwszym przełączeniu procesów, zostanie uzupełniony poprawną wartością
	add	rdi,	VARIABLE_QWORD_SIZE	; pomiń

	; zapisz flagi procesu
	mov	rax,	STATIC_SERPENTINE_RECORD_FLAG_USED | STATIC_SERPENTINE_RECORD_FLAG_ACTIVE | STATIC_SERPENTINE_RECORD_FLAG_DAEMON
	stosq

	; ustaw nazwę procesu
	mov	al,	"c"
	stosb
	mov	al,	"y"
	stosb
	mov	al,	"j"
	stosb
	mov	al,	"o"
	stosb
	mov	al,	"n"
	stosb

	; ustaw liczniki
	inc	qword [variable_multitasking_serpentine_record_counter]
	inc	qword [variable_multitasking_serpentine_record_counter_left_in_page]
	inc	qword [variable_multitasking_serpentine_record_counter_handle]
	inc	qword [variable_multitasking_pid_value_next]

	; połącz koniec serpentyny z początkiem
	mov	rdi,	qword [variable_multitasking_serpentine_start_address]
	mov	qword [rdi + VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_QWORD_SIZE],	rdi

	; włącz przerwanie sprzętowe planisty
	mov	cx,	0
	call	cyjon_programmable_interrupt_controller_enable_irq

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; procedura przełącza procesor na następny proces, poprzedni stan procesora zostanie zachowany na stosie kontekstu poprzedniego procesu
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
irq32:
	; wyłącz przerwania
	cli

	; zachowaj oryginalne rejestry na stos kontekstu procesu/jądra
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; rejestr RSP został już zachowany poprzez wywołanie przerwania sprzętowego IRQ0
	; push	rsp

	push	rbp
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; zachowaj flagi procesora
	pushfq

	; zachowaj rejestry zmiennoprzecinkowe
	mov	rbp,	rsp
	and	bp,	0xF000
	FXSAVE64	[rbp]

	; zwiększ czas aktywności jądra systemu
	inc	qword [variable_system_microtime]

	; pobierz adres aktywnego rekordu serpentyny
	mov	rdi,	qword [variable_multitasking_serpentine_record_active_address]

	; zachowaj aktualny wskaźnik stosu
	mov	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.RSP],	rsp

	; zachowaj adres tablicy PML4
	mov	rax,	cr3
	mov	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.CR3],	rax

	; szukaj następnego aktywnego rekordu w serpentynie
	mov	bx,	STATIC_SERPENTINE_RECORD_FLAG_USED | STATIC_SERPENTINE_RECORD_FLAG_ACTIVE

	; pobiera ilość rekordów pozostałych w serpentynie
	mov	rcx,	qword [variable_multitasking_serpentine_record_counter_left_in_page]
	mov	rdx,	qword [variable_multitasking_serpentine_record_counter_handle]

	; szukaj
	call	cyjon_multitasking_serpentine_find_record.next_record

	; zachowaj liczniki
	mov	qword [variable_multitasking_serpentine_record_counter_left_in_page],	rcx
	mov	qword [variable_multitasking_serpentine_record_counter_handle],	rdx

	; zachowaj nowy adres aktywnego rekordu
	mov	qword [variable_multitasking_serpentine_record_active_address],	rdi

	; załaduj wskaźnik stosu przywracanego procesu i adres tablicy PML4
	mov	rsp,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.RSP]
	mov	rax,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.CR3]
	mov	cr3,	rax

	; wyślij potwierdzenie obsłużenia przerwania sprzętowego
	mov	al,	0x20
	out	0x20,	al

	; przywróć rejestry zmiennoprzecinkowe
	mov	rbp,	rsp
	and	bp,	0xF000
	FXRSTOR64	[rbp]

	; przywróć flagi procesora dla procesu
	popfq

	; przywróć oryginalne rejestry procesu
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rbp

	; rejestr RSP zostanie przywrócony po zakończeniu przerwania sprzętowego IRQ0
	; pop	rsp

	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; włącz przerwania
	sti

	; powrót z przerwania sprzętowego
	iretq

;===============================================================================
; procedura poszukuje nastepny dostępny proces opisany w serpentynie
; IN:
;	rdi - adres bezwzględny aktualnego rekordu
; OUT:
;	rdi - znaleziony nowy rekord lub aktualny jeśli brak innych
cyjon_multitasking_serpentine_find_record:
	; przeszukaj serpentynę od początku
	mov	rdi,	qword [variable_multitasking_serpentine_start_address]

	; zresetuj liczniki
	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - 0x08 ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE
	mov	rdx,	qword [variable_multitasking_serpentine_record_counter]

	; kontynuuj
	jmp	.do_not_leave_me

.next_record:
	; zmniejsz ilość pozostałych rekordów  i pozostałych rekordów w stronie(page)
	dec	rcx
	dec	rdx

	; przesuń na następny rekord
	add	rdi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.do_not_leave_me:
	; pozostały jakiekolwiek rekordy?
	cmp	rdx,	VARIABLE_EMPTY
	ja	.left_something

	; jeśli nie, zacznij przeszukiwać serpentyne od początku
	mov	rdi,	qword [variable_multitasking_serpentine_start_address]

	; resetuj licznik rekordów w serpentynie i stronie(page)
	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - 0x08 ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE
	mov	rdx,	qword [variable_multitasking_serpentine_record_counter]

	; kontynuuj
	jmp	.in_page

.left_something:
	; koniec strony?
	cmp	rcx,	VARIABLE_EMPTY
	ja	.in_page

	; jeśli tak, załaduj adres kontynuacji serpentyny
	and	di,	0xF000
	mov	rdi,	qword [rdi + 0x0FF8]

	; zresetuj licznik rekordów na stronę
	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - 0x08 ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.in_page:
	; pobierz flagi rekordu
	mov	ax,	word [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS]

	; jeśli są identyczne z poszukiwanymi
	and	ax,	bx
	cmp	ax,	bx
	jne	.next_record

	; rekord znaleziony

	; powrót z procedury
	ret
