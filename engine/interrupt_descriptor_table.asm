;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 64 Bitowy kod programu
[BITS 64]

;===============================================================================
; procedura tworzy tablicę IDT do obsługi przerwań i wyjątków
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
interrupt_descriptor_table:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; przygotuj miejsce na Tablicę Deskryptorów Przerwań
	call	cyjon_page_allocate	; plik: engine/paging.asm
	; wyczyść wszystkie rekordy
	call	cyjon_page_clear	; plik: engine/paging.asm

	; zapisz adres Tablicy Deskryptorów Przerwań
	mov	qword [variable_idt_structure.address],	rdi

	; utworzymy obsługę wyjątków procesora
	mov	rax,	idt_cpu_exception_0
	mov	bx,	0x8E00	; typ - wyjątek procesora
	mov	rcx,	1	; wszystkie wyjątki procesora
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_1
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_2
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_3
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_4
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_5
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_6
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_7
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_8
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_9
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_10
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_11
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_12
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_13
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_14
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_default	; zarezerwowany
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_16
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_17
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_18
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_19
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_20
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_default	; 21-29 zarezerwowane
	mov	rcx,	9
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_30
	mov	rcx,	1
	call	recreate_record	; utwórz
	mov	rax,	idt_cpu_exception_default	; zarezerwowane
	call	recreate_record	; utwórz


	; utworzymy obsługę 16 przerwań (zombi) sprzętowych
	; gdyby jakimś cudem wystąpiły
	; co niektóre dostaną prawidłową procedurę obsługi
	mov	rax,	idt_hardware_interrupt_default
	mov	bx,	VARIABLE_IDT_RECORD_TYPE_CPU	; typ - przerwanie sprzętowe
	mov	rcx,	16	; wszystkie przerwania sprzętowe
	call	recreate_record	; utwórz

	; utworzymy obsługę pozostałych 208 przerwań (zombi) programowych
	; tylko jedno z nich (przerwanie 64, 0x40) dostanie prawidłową procedurę obsługi
	mov	rax,	idt_software_interrupt_default
	mov	bx,	VARIABLE_IDT_RECORD_TYPE_SOFTWARE	; typ - przerwanie programowe
	mov	rcx,	208	; pozostałe rekordy w tablicy
	call	recreate_record	; utwórz

	; podłączamy poszczególne procedury obsługi przerwań/wyjątków

	;---------------------------------------------------------------

	; procedura obsługi przerwania sprzętowego zegara
	mov	rax,	irq32	; plik: engine/multitasking.asm
	mov	bx,	VARIABLE_IDT_RECORD_TYPE_HARDWARE	; typ - przerwanie sprzętowe
	mov	rcx,	1	; modyfikuj jeden rekord
	; ustaw adres rekordu
	mov	rdi,	qword [variable_idt_structure.address]
	add	rdi,	0x10 * 32	; podrekord 0
	call	recreate_record

	; procedura obsługi przerwania sprzętowego klawiatury
	mov	rax,	irq33	; plik: engine/keyboard.asm
	call	recreate_record

	;---------------------------------------------------------------

	; procedura obsługi przerwania programowego użytkownika
	mov	rax,	irq64	; plik: engine/multitasking.asm
	mov	bx,	VARIABLE_IDT_RECORD_TYPE_SOFTWARE	; typ - przerwanie sprzętowe
	; ustaw adres rekordu
	mov	rdi,	qword [variable_idt_structure.address]
	add	rdi,	0x10 * 64
	call	recreate_record

	;---------------------------------------------------------------

	; załaduj Tablicę Deskryptorów Przerwań
	lidt	[variable_idt_structure]

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z przerwania
	ret

idt_cpu_exception_0:
	; numer wyjątku procesora
	xor	rax,	rax
	mov	rsi,	text_cpu_exception_0
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_1:
	; numer wyjątku procesora
	mov	rax,	1
	mov	rsi,	text_cpu_exception_1
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_2:
	; numer wyjątku procesora
	mov	rax,	2
	mov	rsi,	text_cpu_exception_2
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_3:
	; numer wyjątku procesora
	mov	rax,	3
	mov	rsi,	text_cpu_exception_3
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_4:
	; numer wyjątku procesora
	mov	rax,	4
	mov	rsi,	text_cpu_exception_4
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_5:
	; numer wyjątku procesora
	mov	rax,	5
	mov	rsi,	text_cpu_exception_5
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_6:
	; numer wyjątku procesora
	mov	rax,	6
	mov	rsi,	text_cpu_exception_6
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_7:
	; numer wyjątku procesora
	mov	rax,	7
	mov	rsi,	text_cpu_exception_7
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_8:
	; numer wyjątku procesora
	mov	rax,	8
	mov	rsi,	text_cpu_exception_8
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_9:
	; numer wyjątku procesora
	mov	rax,	9
	mov	rsi,	text_cpu_exception_9
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_10:
	; numer wyjątku procesora
	mov	rax,	10
	mov	rsi,	text_cpu_exception_10
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_11:
	; numer wyjątku procesora
	mov	rax,	11
	mov	rsi,	text_cpu_exception_11
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_12:
	; numer wyjątku procesora
	mov	rax,	12
	mov	rsi,	text_cpu_exception_12
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_13:
	; numer wyjątku procesora
	mov	rax,	13
	mov	rsi,	text_cpu_exception_13
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_14:
	; numer wyjątku procesora
	mov	rax,	14
	mov	rsi,	text_cpu_exception_14
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_16:
	; numer wyjątku procesora
	mov	rax,	16
	mov	rsi,	text_cpu_exception_16
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_17:
	; numer wyjątku procesora
	mov	rax,	17
	mov	rsi,	text_cpu_exception_17
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_18:
	; numer wyjątku procesora
	mov	rax,	18
	mov	rsi,	text_cpu_exception_18
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_19:
	; numer wyjątku procesora
	mov	rax,	19
	mov	rsi,	text_cpu_exception_19
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_20:
	; numer wyjątku procesora
	mov	rax,	20
	mov	rsi,	text_cpu_exception_20
	jmp	idt_cpu_exception_default.print

idt_cpu_exception_30:
	; numer wyjątku procesora
	mov	rax,	30
	mov	rsi,	text_cpu_exception_30
	jmp	idt_cpu_exception_default.print

;===============================================================================
; procedura podstawowej obsługi wyjątku/przerwania procesora
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
idt_cpu_exception_default:
	; wyświetl domyślny tekst
	mov	rsi,	text_kernel_panic_cpu_interrupt

.print:
	mov	bl,	VARIABLE_COLOR_LIGHT_RED
	mov	rcx,	VARIABLE_FULL
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	call	cyjon_screen_print_string

	; ustaw wskaźnik do procesu serpentyny
	mov	rdi,	qword [variable_multitasking_serpentine_record_active_address]

	; wyświetl nazwę procesu
	mov	rsi,	rdi
	add	rsi,	VARIABLE_TABLE_SERPENTINE_RECORD.NAME
	call	cyjon_screen_print_string

	; przesuń kursor do następnej linii
	mov	rsi,	text_return
	call	cyjon_screen_print_string

	; wyświetl informacje, dlaczego proces został zatrzymany
	mov	rsi,	text_process_prohibited_operation
	call	cyjon_screen_print_string

	; ustaw flagę "proces zakończony", "rekord nieaktywny"
	and	byte [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	~STATIC_SERPENTINE_RECORD_FLAG_ACTIVE
	or	byte [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	STATIC_SERPENTINE_RECORD_FLAG_CLOSED

	; zakończ obsługę procesu
	sti
	hlt

	; zatrzymaj dalsze wykonywanie kodu procesu, jeśli coś poszło nie tak??
	jmp	$

;===============================================================================
; procedura podstawowej obsługi przerwania sprzętowego
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
idt_hardware_interrupt_default:
	; zachowaj oryginalne rejestry
	push	rax
	pushf

	; poinformuj kontroler PIC o obsłużeniu przerwania sprzętowego
	mov	al,	0x20

	; przerwane obsługiwane w trybie kaskady?
	cmp	byte [variable_network_i8254x_irq],	8
	jb	.no_cascade

	; wyślij do kontrolera "kaskadowego"
	out	VARIABLE_PIC_COMMAND_PORT1,	al

.no_cascade:
	; wyślij do kontrolera głównego
	out	VARIABLE_PIC_COMMAND_PORT0,	al

	; przywróć oryginalne rejestry
	popf
	pop	rax

	; powrót z przerwania sprzetowego
	iretq

;===============================================================================
; procedura podstawowej obsługi przerwania programowego
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
idt_software_interrupt_default:
	; wyświetl wskaźnik do nazwy procesu
	mov	bl,	VARIABLE_COLOR_LIGHT_RED
	mov	rcx,	VARIABLE_FULL
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_arrow_right
	call	cyjon_screen_print_string

	; ustaw wskaźnik do procesu serpentyny
	mov	rdi,	qword [variable_multitasking_serpentine_record_active_address]

	; wyświetl nazwę procesu
	mov	rsi,	rdi
	add	rsi,	VARIABLE_TABLE_SERPENTINE_RECORD.NAME
	call	cyjon_screen_print_string

	; przesuń kursor do następnej linii
	mov	rsi,	text_return
	call	cyjon_screen_print_string

	; wyświetl informacje, dlaczego proces został zatrzymany
	mov	rsi,	text_process_prohibited_operation
	call	cyjon_screen_print_string

	; ustaw flagę "proces zakończony", "rekord nieaktywny"
	and	byte [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	~STATIC_SERPENTINE_RECORD_FLAG_ACTIVE
	or	byte [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	STATIC_SERPENTINE_RECORD_FLAG_CLOSED

	; zakończ obsługę procesu
	sti
	hlt

	; zatrzymaj dalsze wykonywanie kodu procesu, jeśli coś poszło nie tak??
	jmp	$

;===============================================================================
; procedura tworzy/modyfikuje rekord w Tablicy Deskryptorów Przerwań
; IN:
;	rax	- adres logiczny procesury obsługi wyjątku/przerwania
;	bx	- typ: wyjątek/przerwanie(sprzętowe/programowe)
;	rcx	- ilość kolejnych rekordów o tej samej procedurze obsługi
;	rdi	- adres logiczny rekordu w Tablicy Deskryptorów Przerawń do modyfikacji
; OUT:
;	rdi	- adres kolejnego rekordu w Tablicy Deskryptorów Przerwań
;
; pozostałe rejestry zachowane
recreate_record:
	; zachowaj oryginalny rejestr
	push	rcx

.next:
	; zachowaj adres procedury obsługi
	push	rax

	; załaduj do tablicy adres obsługi wyjątku (bity 15...0)
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; selektor deskryptora kodu (GDT)
	mov	ax,	0x0008
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; typ: wyjątek/przerwanie(sprzętowe/programowe)
	mov	ax,	bx
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; przywróć wartość zmiennej
	mov	rax,	qword [rsp]

	; przemieszczamy do ax bity 31...16 z rax
	shr	rax,	16
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; przemieszczamy do eax bity 63...32 z rax
	shr	rax,	16
	stosd	; zapisz zawartość rejestru EAX pod adres w rejestrze RDI, zwiększ rejestr RDI o 4 Bajty

	; pola zastrzeżone
	xor	eax,	eax
	stosd	; zapisz zawartość rejestru EAX pod adres w rejestrze RDI, zwiększ rejestr RDI o 4 Bajty

	; przywróć adres procedury obsługi
	pop	rax

	; utwórz pozostałe rekordy
	loop	.next

	; przywróć oryginalny rejestr
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
; podpięcie procedury obsługi przerwania
; IN:
;	rax - numer przerwania, pod które podpiąć procedurę
;	rdi - adres procedury obsługi przerwania
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_interrupt_descriptor_table_isr_hardware_mount:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; ustaw na swoje miejsca
	xchg	rax,	rdi

	; oblicz przesunięcie
	shl	rdi,	4	; * 0x10
	add	rdi,	0x10 * 32
	add	rdi,	qword [variable_idt_structure.address]

	; procedura obsługi przerwania sprzętowego zegara
	mov	bx,	VARIABLE_IDT_RECORD_TYPE_HARDWARE	; typ - przerwanie sprzętowe
	mov	rcx,	1	; modyfikuj jeden rekord
	call	recreate_record

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
