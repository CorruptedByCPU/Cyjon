;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_TASK_EFLAGS_if			equ	000000000000001000000000b
KERNEL_TASK_EFLAGS_zf			equ	000000000000000001000000b
KERNEL_TASK_EFLAGS_cf			equ	000000000000000000000001b
KERNEL_TASK_EFLAGS_df			equ	000000000000010000000000b
KERNEL_TASK_EFLAGS_default		equ	KERNEL_TASK_EFLAGS_if

KERNEL_TASK_FLAG_active			equ	0000000000000001b
KERNEL_TASK_FLAG_closed			equ	0000000000000010b
KERNEL_TASK_FLAG_service		equ	0000000000000100b
KERNEL_TASK_FLAG_processing		equ	0000000000001000b
KERNEL_TASK_FLAG_secured		equ	0000000000010000b
KERNEL_TASK_FLAG_thread			equ	0000000000100000b

KERNEL_TASK_FLAG_active_bit		equ	0
KERNEL_TASK_FLAG_closed_bit		equ	1
KERNEL_TASK_FLAG_daemon_bit		equ	2
KERNEL_TASK_FLAG_processing_bit		equ	3
KERNEL_TASK_FLAG_secured_bit		equ	4
KERNEL_TASK_FLAG_thread_bit		equ	5

KERNEL_TASK_STACK_address		equ	(KERNEL_MEMORY_HIGH_VIRTUAL_address << STATIC_MULTIPLE_BY_2_shift) - KERNEL_TASK_STACK_SIZE_byte
KERNEL_TASK_STACK_SIZE_byte		equ	KERNEL_PAGE_SIZE_byte

struc	KERNEL_TASK_STRUCTURE
	.cr3				resb	8	; adres tablicy PML4 procesu
	.rsp				resb	8	; ostatni znany wskaźnik szczytu stosu kontekstu procesu
	.cpu				resb	8	; identyfikator procesora logicznego, obsługującego w danym czasie proces
	.pid				resb	8	; identyfikator procesu
	.time				resb	8	; czas uruchomienia procesu względem czasu życia jądra systemu
	.knot				resb	8	; wskaźnik do supła katalogu roboczego procesu
	.flags				resb	2	; flagi stanu procesu
	.stack				resb	2	; rozmiar przestrzeni stosu w stronach
	.length				resb	1	; ilość znaków w nazwie procesu
	.name				resb	255	; nazwa procesu
	.SIZE:
endstruc

struc	KERNEL_TASK_STRUCTURE_IRETQ
	.rip				resb	8
	.cs				resb	8
	.eflags				resb	8
	.rsp				resb	8
	.ds				resb	8
endstruc

kernel_task_debug_semaphore		db	STATIC_FALSE

kernel_task_address			dq	STATIC_EMPTY
kernel_task_active_list			dq	STATIC_EMPTY

kernel_task_pid_semaphore		db	STATIC_FALSE
kernel_task_pid				dq	STATIC_EMPTY

;===============================================================================
kernel_task:
	; włączono tryb debugowania?
	cmp	byte [kernel_task_debug_semaphore],	STATIC_FALSE
	je	.no	; nie

	; tak
	xchg	bx,bx

.no:
	; zachowaj oryginalne rejestry na stosie kontekstu procesu/jądra
	push	rax
	push	rdi

	; pobierz identyfikator procesora logicznego
	call	kernel_apic_id_get

	; zachowaj oryginalne rejestry na stosie kontekstu procesu/jądra
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rbp
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; wyłącz flagę DF
	cld

	; wylicz adres względny wpisu na liście aktywnych zadań
	mov	rbx,	rax
	shl	rbx,	STATIC_MULTIPLE_BY_8_shift

	; pobierz wskaźnik do aktywnego zadania
	mov	rsi,	qword [kernel_task_active_list]
	mov	rdi,	qword [rsi + rbx]

	; zachowaj rejestry "zmiennoprzecinkowe"
	mov	rbp,	KERNEL_STACK_pointer
	FXSAVE64	[rbp]

	; zachowaj w kolejce aktualny wskaźnik stosu kontekstu zadania
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.rsp],	rsp

	; zachowaj identyfikator procesora
	push	rax

	; zachowaj w kolejce adres tablicy PML4 zadania
	mov	rax,	cr3
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.cr3],	rax

	; usuń z zadania informacje o przydzielonym procesorze logicznym
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.cpu],	STATIC_EMPTY

	; zwolnij zadanie (następny procesor logiczny będzie mógł je rozpocząć)
	and	word [rdi + KERNEL_TASK_STRUCTURE.flags],	~KERNEL_TASK_FLAG_processing

	; przelicz adres pośredni zadania na numer zadania w kolejce
	movzx	eax,	di
	and	ax,	~KERNEL_PAGE_mask
	mov	rcx,	KERNEL_TASK_STRUCTURE.SIZE
	xor	edx,	edx
	div	rcx

	; maksymalna ilość zadań w bloku kolejki
	mov	ecx,	STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

	; oblicz ilość rekordów do końca bloku kolejki
	sub	rcx,	rax

	; przywróć identyfikator procesora
	pop	rax

	; szukaj następnego zadania do uruchomienia
	jmp	.next

.block:
	; załaduj następny blok kolejki
	and	di,	KERNEL_PAGE_mask
	mov	rdi,	qword [rdi + STATIC_STRUCTURE_BLOCK.link]

.ap_entry:
	; zresetuj ilość zadań w kolejce
	mov	ecx,	STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

	; sprawdź pierwsze zadanie w kolejki
	jmp	.check

.next:
	; pozostały zadania w bloku?
	dec	ecx
	jz	.block	; nie

	; przesuń wskaźnik na następne zadanie
 	add	rdi,	KERNEL_TASK_STRUCTURE.SIZE

.check:
	; czy wpis jest pusty?
	test	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_secured
	jz	.next	; tak

	; czy wpis jest już obsługiwany przez inny procesor logiczny?
	lock	bts	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_processing_bit
	jc	.next	; tak, sprawdź następne zadanie

	; czy wpis jest aktywny?
	test	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active
	jnz	.active	; tak

	; proces jest uśpiony lub w trakcie zamykania

	; zwolnij dostęp do procesu
	and	word [rdi + KERNEL_TASK_STRUCTURE.flags],	~KERNEL_TASK_FLAG_processing

	; szukaj dalej
	jmp	.next

.active:
	; zachowaj informacje w wpisie o procesorze logicznym przetwarzającym zadanie
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.cpu],	rax

	; zachowaj nowy adres aktywnego zadania dla danego procesora logicznego
	mov	qword [rsi + rbx],	rdi

	; załaduj wskaźnik stosu kontekstu przywracanego zadania i adres tablicy PML4
	mov	rsp,	qword [rdi + KERNEL_TASK_STRUCTURE.rsp]
	mov	rax,	qword [rdi + KERNEL_TASK_STRUCTURE.cr3]
	mov	cr3,	rax

	; przywróć rejestry "zmiennoprzecinkowe"
	mov	rbp,	KERNEL_STACK_pointer
	FXRSTOR64	[rbp]

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
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

.leave:
	; wywołaj przerwanie czasowe po upłynięciu (jednej jednostki czasu) cdn.
	mov	rdi,	qword [kernel_apic_base_address]
	mov	dword [rdi + KERNEL_APIC_TICR_register],	DRIVER_RTC_Hz

	; poinformuj APIC o obsłużeniu aktualnego przerwania sprzętowego
	mov	dword [rdi + KERNEL_APIC_EOI_register],	STATIC_EMPTY

	; przywróć oryginalne rejestry procesu
	pop	rdi
	pop	rax

	; powrót z procedury
	iretq

	macro_debug	"kernel_task"

;===============================================================================
; wejście:
;	bx - flagi zadania
;	cl - ilość znaków w nazwie procesu
;	rsi - wskaźni do nazwy procesu
;	r11 - adres tablicy PML4 zadania
; wyjście:
;	Flaga CF, jeśli brak wolnego miejsca w kolejce
;	rcx - identyfikator nowego procesu
;	rdi - wskaźnik do zadania
kernel_task_add:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi
	push	rcx
	push	rdi

	; znajdź wolny wpis na liście zadań
	call	kernel_task_queue
	jc	.end

	; zachowaj wskaźnik pozycji zadania w kolejce
	push	rdi

	; zapisz adres tablicy PML4 zadania
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.cr3],	r11

	; zapisz spreparowany wskaźnik szczytu stosu kontekstu zadania
	mov	rax,	KERNEL_STACK_pointer - (STATIC_QWORD_SIZE_byte * 0x14)
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.rsp],	rax

	; pobierz katalog roboczy rodzica
	call	kernel_task_active
	mov	rax,	qword [rdi + KERNEL_TASK_STRUCTURE.knot]

	; przywróć wskaźnik pozycji zadania w kolejce
	pop	rdi

	; ustaw katalog roboczy procesu na podstawie rodzica
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.knot],	rax

	; pobierz unikalny numer PID
	call	kernel_task_pid_get

	; ustaw PID zadania
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.pid],	rcx

	; zwróć numer PID do procesu rodzica, pobierz ilość znaków w nazwie procesu
	xchg	rcx,	qword [rsp + STATIC_QWORD_SIZE_byte]

	; zachowaj w wpisie zadania, czas jego uruchomienia
	mov	rax,	qword [driver_rtc_microtime]
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.time],	rax

	; aktualizuj flagi zadania
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	bx

	; domyślny rozmiar stosu
	mov	word [rdi + KERNEL_TASK_STRUCTURE.stack],	KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift

	; zwróć wskaźnik do zadania
	mov	qword [rsp],	rdi

	; wstaw ilość znaków reprezentujących nazwę procesu
	mov	byte [rdi + KERNEL_TASK_STRUCTURE.length],	cl

	; zapisz nazwę procesu w wpisie
	and	ecx,	STATIC_BYTE_mask
	add	rdi,	KERNEL_TASK_STRUCTURE.name
	rep	movsb

	; flaga, sukces
	clc

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rsi
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_task_add"

;===============================================================================
; wyjście:
;	Flaga CF - jeśli kolejka pełna
;	rdi - wskaźnik do wolnej pozycji na kolejce zadań danego procesora logicznego
kernel_task_queue:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; przeszukaj od początku kolejkę za wolnym rekordem
	mov	rdi,	qword [kernel_task_address]

.restart:
	; ilość wpisów na blok danych kolejki zadań
	mov	rcx,	STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

.next:
	; wpis wolny?
	lock	bts word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_secured_bit
	jnc	.found	; tak

	; prdesuń wskaźnik na następny wpis
	add	rdi,	KERNEL_TASK_STRUCTURE.SIZE

	; pozostały wpisy w bloku?
	dec	rcx
	jnz	.next

	; zachowaj wskaźnik początku ostatniego bloku kolejki zadań
	and	di,	KERNEL_PAGE_mask
	mov	rsi,	rdi

	; pobierz adres następnego bloku kolejki
	mov	rdi,	qword [rdi + STATIC_STRUCTURE_BLOCK.link]

	; powróciliśmy na początek kolejki?
	cmp	rdi,	qword [kernel_task_address]
	jne	.restart	; nie

	; przygotuj następny blok do rozszerzenia kolejki
	call	kernel_memory_alloc_page
	jc	.error

	; wyczyść blok i dołącz do końca przestrzeni kolejki
	call	kernel_page_drain
	mov	qword [rsi + STATIC_STRUCTURE_BLOCK.link],	rdi

	; połącz koniec kolejki z początkiem
	mov	rsi,	qword [kernel_task_address]
	mov	qword [rdi + STATIC_STRUCTURE_BLOCK.link],	rsi

	; w nowym bloku automatycznie znajduje się wolny wpis
	jmp	.found

.error:
	; brak wolnego miejsca w kolejce

	; zwolnij zmienną lokalną
	add	rsp,	STATIC_QWORD_SIZE_byte

	; flaga, błąd
	stc

	; koniec obsługi procedury
	jmp	.end

.found:
	; zwróć adres kolejki i wolnego wpisu
	mov	qword [rsp],	rdi

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_task_queue"

;===============================================================================
; wyjście:
;	ecx - unikalny identyfikator
kernel_task_pid_get:
	; zablokuj dostęp do podprocedury
	macro_close	kernel_task_pid_semaphore, 0

.next:
	; pobierz unikalny numer PID
	mov	rcx,	qword [kernel_task_pid]
	inc	qword [kernel_task_pid]

	; PID unikalny?
	call	kernel_task_pid_check
	jnc	.next	; nie, pobierz następny

	; zwolnij dostęp do podprocedury
	mov	byte [kernel_task_pid_semaphore],	STATIC_FALSE

	; powrót z podprocedury
	ret

	macro_debug	"kernel_task_pid_get"

;===============================================================================
; wejście:
;	rcx - pid procesu poszukiwanego
; wyjście:
;	Flaga CF - jeśli proces nie istnieje
kernel_task_pid_check:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; przeszukaj kolejkę od początku
	mov	rdi,	qword [kernel_task_address]

.restart:
	; ilość wpisów na blok danych kolejki zadań
	mov	rax,	STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

.next:
	; znaleziono poszukiwany wpis??
	cmp	qword [rdi + KERNEL_TASK_STRUCTURE.pid],	rcx
	je	.found	; tak

.omit:
	; prdesuń wskaźnik na następny wpis
	add	rdi,	KERNEL_TASK_STRUCTURE.SIZE

	; pozostały wpisy w bloku?
	dec	rax
	jnz	.next

	; pobierz adres następnego bloku kolejki
	and	di,	KERNEL_PAGE_mask
	mov	rdi,	qword [rdi + STATIC_STRUCTURE_BLOCK.link]

	; powróciliśmy na początek kolejki?
	cmp	rdi,	qword [kernel_task_address]
	jne	.restart	; nie

.error:
	; brak procesu w kolejce

	; flaga, błąd
	stc

	; koniec obsługi procedury
	jmp	.end

.found:
	; proces zamknięty?
	cmp	byte [rdi + KERNEL_TASK_STRUCTURE.flags],	STATIC_EMPTY
	je	.omit	; tak

	; proces jest zamknięty?
	bt	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_closed_bit

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_task_pid_check"

;===============================================================================
; wyjście:
;	rax - PID procesu aktywnego
kernel_task_active_pid:
	; zachowaj oryginalne rejestry
	push	rdi

	; pobierz wskaźnik do aktywnego procesu
	call	kernel_task_active

	; zwróć PID procesu
	mov	rax,	qword [rdi + KERNEL_TASK_STRUCTURE.pid]

	; przywróć oryginalne rejestry
	pop	rdi

	; powrót z podprocedury
	ret

	macro_debug	"kernel_task_active_pid"

;===============================================================================
; wyjście:
;	rdi - wskaźnik do pozycji zadania procesora logicznego
kernel_task_active:
	; zachowaj oryginalne rejestry
	push	rax

	; wyłącz wywłaszczanie (rezerwujemy ID procesora obsługującego procedurę)
	cli

	; pobierz identyfikator procesora logicznego
	call	kernel_apic_id_get

	; ustaw wskaźnik na pozycje zadania procesora logicznego
	shl	rax,	STATIC_MULTIPLE_BY_8_shift
	mov	rdi,	qword [kernel_task_active_list]
	mov	rdi,	qword [rdi + rax]

	; włącz wywłaszczanie
	sti

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_task_active"

;===============================================================================
kernel_task_kill:
	; pobierz wskaźnik do wątku w kolejce zadań
	call	kernel_task_active

	; oznacz wątek jako zakończony
	and	word [rdi + KERNEL_TASK_STRUCTURE.flags],	~KERNEL_TASK_FLAG_active
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_closed

	; zatrzymaj dalsze wykonywanie kodu wątku
	jmp	$

	macro_debug	"kernel_task_kill_me"
