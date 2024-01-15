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
; procedura przygotowuje miejsce w pamięci pod proces demona i dodaje do kolejki serpentyny
; IN:
;	rcx - ilość znaków w nazwie demona
;	rdx - wskaźnik do procedury demona
;	rsi - wskaźnik do nazwy demona
;
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_process_init_daemon:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r11

	; przygotuj tablice PML4 i stos kontekstu
	call	cyjon_process_init_phase_0

	; odstaw na stos kontekstu demona spreparowane dane powrotu z przerwania IRQ0

	; RIP
	mov	rax,	rdx	; wskaźnik procedury demona
	stosq	; zapisz

	; CS
	mov	rax,	VARIABLE_KERNEL_CS_SELECTOR
	stosq	; zapisz

	; EFLAGS
	mov	rax,	VARIABLE_EFLAGS_IF
	stosq	; zapisz

	; RSP
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS
	stosq	; zapisz

	; DS
	mov	rax,	VARIABLE_KERNEL_DS_SELECTOR
	stosq	; zapisz

	; pobierz adres wolnego rekordu w tablicy serpentyny (kolejce procesów)
	call	cyjon_process_init_phase_1

	; przywróć aktualny dostępny numer PID
	mov	rax,	rbx

	; zapisz PID procesu do rekordu
	stosq

	; zapisz CR3 procesu
	mov	rax,	r11
	stosq

	; zapisz adres szczytu stosu kontekstu procesu do rekordu
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - (21 * VARIABLE_QWORD_SIZE )
	stosq

	; ustaw flagę rekordu na aktywny
	mov	rax,	STATIC_SERPENTINE_RECORD_FLAG_USED | STATIC_SERPENTINE_RECORD_FLAG_ACTIVE | STATIC_SERPENTINE_RECORD_FLAG_DAEMON
	stosq

	; zwiększ ilość rekordów/procesów przechowywanych w tablicy
	inc	qword [variable_multitasking_serpentine_record_counter]

	; załaduj nazwę demona do rekordu serpentyny
	mov	rcx,	qword [rsp + 0x20]
	mov	rsi,	qword [rsp + 0x10]
	rep	movsb

	; przywróć oryginalne rejestry
	pop	r11
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; procedura uruchamia nowy proces, przydzielając pamięć i numer identyfikacyjny
; IN:
;	rcx - ilość znaków w nazwie pliku
;	rdx - rozmiar argumentów do przetransferowania
;	rsi - wskaźnik do nazwy pliku i argumentów
;	rdi - wskaźnik do ciągu argumentów
;
; OUT:
;	rbx - kod błędu, jeśli ZERO - wszystko ok
;	rcx - numer PID uruchomionego procesu
;
; pozostałe rejestry zachowane
cyjon_process_init:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r11

	; zmienne lokalne
	push	VARIABLE_EMPTY

	; kod błędu
	mov	rbx,	VARIABLE_PROCESS_ERROR_FILE_NOT_FOUND

	; szukaj pliku w wirtualnym systemie plików
	call	cyjon_vfs_file_find
	jc	.end	; nie znaleziono

	; kod błędu
	mov	rbx,	VARIABLE_PROCESS_ERROR_NO_EXECUTE

	; sprawdź czy plik jest wykonywalny
	bt	qword [rdi + STRUCTURE_VFS_KNOT.permission],	VARIABLE_PERMISSION_FILE_OTHER_EXECUTE_BIT
	jnc	.end	; nie

	; pobierz rozmiar pliku w Bajtach
	mov	rcx,	qword [rdi + STRUCTURE_VFS_KNOT.size]
	push	rcx

	; zaokrąglij rozmiar pliku do pełnej strony (w górę)
	and	cx,	0xF000
	cmp	rcx,	qword [rsp]
	je	.size_ok

	; jeśli tak, zwiększ rozmiar pliku o jedną stronę
	add	rcx,	VARIABLE_MEMORY_PAGE_SIZE

.size_ok:
	; usuń zmienną lokalną
	add	rsp,	0x08

	; zamień rozmiar pliku na strony
	shr	rcx,	VARIABLE_DIVIDE_BY_4096

	; przygotuj przestrzeń pod proces w 254 rekordzie tablicy PML4 jądra systemu (limit rozmiaru programu 512 GiB)
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - ( VARIABLE_MEMORY_PML4_RECORD_SIZE * 2 )
	mov	rbx,	VARIABLE_MEMORY_PAGE_FLAG_AVAILABLE + VARIABLE_MEMORY_PAGE_FLAG_WRITE + VARIABLE_MEMORY_PAGE_FLAG_USER
	mov	r11,	cr3	; tablica PML4 aktualnego procesu
	call	cyjon_page_map_logical_area

	; sprawdź kod błędu alokacji pamięci
	cmp	rax,	VARIABLE_EMPTY
	ja	.backward_process_init	; brak miejsca, zakończ proces uruchamiania procesu

	; załaduj plik do pamięci pod przygotowaną przestrzeń
	mov	rsi,	qword [rdi]	; numer pierwszego bloku danych pliku
	mov	rdi,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - ( VARIABLE_MEMORY_PML4_RECORD_SIZE * 2 )
	call	cyjon_vfs_file_read

	; przygotuj miejsce dla tablicy PML4 procesu
	call	cyjon_page_allocate

	; sprawdź czy przydzieliło stronę
	cmp	rdi,	VARIABLE_EMPTY
	je	.backward_process_init	; nie, zakończ procedurę uruchamiania procesu

	; zwiększono rozmiar stronicowania
	inc	qword [variable_binary_memory_map_paged]

	; załaduj tablicę PML4 procesu
	mov	r11,	rdi

	; czy przesłano argumenty?
	cmp	qword [rsp + VARIABLE_QWORD_SIZE * 0x03],	VARIABLE_EMPTY
	je	.no

	; zachowaj
	mov	qword [rsp],	rdi

	; przygotuj miejsce dla argumentów przesłanych do procesu
	call	cyjon_page_allocate

	; przynano miejsce?
	cmp	rdi,	VARIABLE_EMPTY
	je	.backward_process_init

	; zwiększono rozmiar buforów
	inc	qword [variable_binary_memory_map_cached]

	; przywróć adres tablicy PML4, zachowaj adres przestrzeni argumentów
	xchg	rdi,	qword [rsp]

.no:
	; mapuj tablicę PML4 aktualnego procesu do nowego
	mov	rsi,	cr3
	mov	rcx,	255
	rep	movsq	; kopiuj

	; przesuń załadowany program w odpowiednie miejsce pamięci logicznej nowej tablicy PML4 procesu
	mov	rax,	qword [r11 + 0x07F0]
	mov	qword [r11 + 0x0800],	rax
	mov	rax,	cr3
	mov	qword [rax + 0x07F0],	VARIABLE_EMPTY
	mov	qword [r11 + 0x07F0],	VARIABLE_EMPTY

	; usuń stos aktualnego procesu
	mov	qword [r11 + 0x0FF8],	VARIABLE_EMPTY
	; usuń stos kontekstu aktualnego procesu
	mov	qword [r11 + 0x07F8],	VARIABLE_EMPTY

	; przygotuj miejsce pod stos procesu
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS + VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - 0x1000	; ostatnie 4 KiB pamięci logicznej
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	rcx,	1	; rozmiar stosu, jedna strona (4096 Bajtów)
	call	cyjon_page_map_logical_area	; wykonaj

	; sprawdź kod błędu alokacji pamięci
	cmp	rax,	VARIABLE_EMPTY
	ja	.backward_process_init	; brak miejsca, zakończ proces uruchamiania procesu

	; utwórz stos kontekstu procesu
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - VARIABLE_MEMORY_PAGE_SIZE	; ostatnie 4 KiB Low Memory
	mov	rbx,	0x03	; ustaw flagi 4 KiB, Administrator, 4 KiB, Odczyt/Zapis, Dostępna
	mov	rcx,	1	; jedna strona o rozmiarze 4 KiB
	call	cyjon_page_map_logical_area	; wykonaj

	; sprawdź kod błędu alokacji pamięci
	cmp	rax,	VARIABLE_EMPTY
	ja	.backward_process_init	; brak miejsca, zakończ proces uruchamiania procesu

	; odłóż na stos kontekstu procesu spreparowane dane powrotu z planisty
	mov	rdi,	qword [r8]
	and	di,	0xFFF0	; usuń właściwości strony z adresu

	; wyczyść stos kontekstu procesu
	call	cyjon_page_clear

	; przesuń wskaźnik na spreparowany wskaźnik szczytu stosu kontekstu procesu
	add	rdi,	VARIABLE_MEMORY_PAGE_SIZE - ( 5 * VARIABLE_QWORD_SIZE )

	; odstaw na stos kontekstu procesu spreparowane dane powrotu z przerwania IRQ0

	; RIP
	mov	rax,	VARIABLE_MEMORY_HIGH_REAL_ADDRESS
	stosq	; zapisz

	; CS
	mov	rax,	VARIABLE_PROCESS_CS_SELECTOR | VARIABLE_SELECTOR_TYPE_PROCESS
	stosq	; zapisz

	; EFLAGS
	mov	rax,	VARIABLE_EFLAGS_IF
	stosq	; zapisz

	; RSP
	mov	rax,	VARIABLE_EMPTY
	stosq	; zapisz

	; DS
	mov	rax,	VARIABLE_PROCESS_DS_SELECTOR | VARIABLE_SELECTOR_TYPE_PROCESS
	stosq	; zapisz

	; pobierz adres wolnego rekordu w tablicy serpentyny (kolejce procesów)
	call	cyjon_process_init_phase_1

	; sprawdź czy przydzielono numer procesu
	cmp	rbx,	VARIABLE_EMPTY
	je	.backward_process_init

	; ustaw aktualny dostępny numer PID
	mov	rax,	rbx

	; zachowaj adres rekordu
	push	rdi

	; zapisz PID procesu do rekordu
	stosq

	; zapisz CR3 procesu
	mov	rax,	r11
	stosq

	; zapisz adres szczytu stosu kontekstu procesu do rekordu
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - (21 * VARIABLE_QWORD_SIZE )
	stosq

	; ustaw flagę rekordu na aktywny
	mov	rax,	STATIC_SERPENTINE_RECORD_FLAG_USED | STATIC_SERPENTINE_RECORD_FLAG_ACTIVE
	stosq

	; zwiększ ilość rekordów/procesów przechowywanych w tablicy
	inc	qword [variable_multitasking_serpentine_record_counter]

	; załaduj nazwę demona do rekordu serpentyny
	mov	rcx,	qword [rsp + VARIABLE_QWORD_SIZE * 0x07]
	mov	rsi,	qword [rsp + VARIABLE_QWORD_SIZE * 0x05]
	rep	movsb

	; przywróć adres rekordu
	pop	rdx

	; przekazano do procesu argumenty?
	cmp	qword [rsp],	VARIABLE_EMPTY
	je	.no_args

	; przekaż do procesu wskaźnk do ciągu argumentów
	mov	rdi,	qword [rsp]
	mov	qword [rdx + VARIABLE_TABLE_SERPENTINE_RECORD.ARGS],	rdi

	; wyczyść
	call	cyjon_page_clear

	; pobierz wskaźnik do oryginału argumentów
	mov	rsi,	qword [rsp + VARIABLE_QWORD_SIZE * 0x03]
	; rozmiar ciągu argumentów
	mov	rcx,	qword [rsp + VARIABLE_QWORD_SIZE * 0x05]

	; zapisz rozmiar ciągu argumentów do rekordu serpentyny
	mov	qword [rdx + VARIABLE_TABLE_SERPENTINE_RECORD.SIZE],	rcx

	; zapisz rozmiar listy argumentów
	mov	qword [rdi],	rcx
	add	rdi,	VARIABLE_QWORD_SIZE

	; skopiuj argumenty z oryginału do kopii
	rep	movsb

.no_args:
	; zwróć w rcx numer PID
	mov	qword [rsp + VARIABLE_QWORD_SIZE * 0x06],	rbx

	; kod błędu, sukces
	xor	rbx,	rbx

.end:
	; usuń zmienne lokalne
	pop	rax

	; przywróć oryginalne rejestry
	pop	r11
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

.backward_process_init:
	; zwolnij pamięć zajętą procedurę
	mov	rdi,	r11	; załaduj adres tablicy PML4 procesu
	add	rdi,	255 * 0x08	; rozpocznij zwalnianie przestrzeni od rekordu 254
	mov	rbx,	4	; ustaw poziom tablicy przetwarzanej
	mov	rcx,	257	; ile pozostało rekordów w tablicy PML4 do zwolnienia
	call	cyjon_page_release_area.loop

	; zwolnij pamięć zajętą w przestrzeni jądra systemu
	mov	rdi,	cr3	; załaduj adres tablicy PML4 procesu
	add	rdi,	254 * 0x08	; rozpocznij zwalnianie przestrzeni od rekordu 254
	mov	rbx,	4	; ustaw poziom tablicy przetwarzanej
	mov	rcx,	258	; ile pozostało rekordów w tablicy PML4 do zwolnienia
	call	cyjon_page_release_area.loop

	; kod błędu
	mov	rbx,	VARIABLE_PROCESS_ERROR_NO_FREE_MEMORY

	; koniec
	jmp	.end

cyjon_process_init_phase_0:
	; przygotuj miejsce dla tablicy PML4
	call	cyjon_page_allocate

	; zwiększono rozmiar stronicowania
	inc	qword [variable_binary_memory_map_paged]

	; zachowaj adres tablicy PML4
	mov	r11,	rdi

	; kopiuj zawartość tablicy PML4 jądra do tablicy PML4
	mov	rsi,	cr3	; tablica PML4 jądra systemu
	mov	rcx,	512	; 512 rekordów
	rep	movsq	; kopiuj

	; usuń stos kontekstu jądra, zostanie utworzony nowy
	mov	qword [r11 + 0x07F8],	VARIABLE_EMPTY

	; utwórz stos kontekstu demona
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - 0x1000	; ostatnie 4 KiB Low Memory
	mov	rcx,	1	; jedna strona o rozmiarze 4 KiB
	mov	rbx,	0x03	; ustaw flagi 4 KiB, Administrator, 4 KiB, Odczyt/Zapis, Dostępna
	call	cyjon_page_map_logical_area	; wykonaj

	; odłóż na stos kontekstu demona spreparowane dane powrotu z planisty
	mov	rdi,	qword [r8]
	and	di,	0xFFF0	; usuń właściwości strony z adresu

	; wyczyść stos kontekstu demona
	call	cyjon_page_clear

	; przesuń wskaźnik na spreparowany wskaźnik szczytu stosu kontekstu demona
	add	rdi,	0x1000 - ( 5 * 0x08 )

	; powrót z procedurya
	ret

cyjon_process_init_phase_1:
	; przywróć adres tablicy PML4 demona
	mov	rax,	r11

	; znajdź wolny rekord w serpentynie
	mov	rdi,	qword [variable_multitasking_serpentine_start_address]

	; poszukiwana flaga rekordu w serpentynie
	xor	bx,	bx

.next:
	; przesuń na następny rekord
	add	rdi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

	; koniec rekordów w części serpentyny?
	mov	cx,	di
	and	cx,	0x0FFF
	cmp	cx,	0x0FF8
	jne	.in_page

	; zładuj adres kolejnej części/strony serpentyny
	mov	rcx,	qword [rdi]

	; koniec serpentyny?
	cmp	rcx,	qword [variable_multitasking_serpentine_start_address]
	jne	.not_at_end

	; rozszerz serpentynę

	; zachowaj wskaźnik aktualnego końca serpentyny
	mov	rdx,	rdi

	; przygotuj miejsce na kolejną część/stronę
	call	cyjon_page_allocate

	; sprawdź czy przydzielono stronę
	cmp	rdi,	VARIABLE_EMPTY
	je	.no_memory

	; zwiększono rozmiar buforów
	inc	qword [variable_binary_memory_map_cached]

	; wyczyść stronę
	call	cyjon_page_clear

	; pobierz adres początku serpentyny
	mov	rcx,	qword [variable_multitasking_serpentine_start_address]
	; zachowaj adres na końcu nowej części/strony serpentyny
	mov	qword [rdi + VARIABLE_MEMORY_PAGE_SIZE - 0x08],	rcx

	; załaduj na koniec starej części/strony serpentyny adres nowej części
	mov	qword [rdx],	rdi
	; zwróć adres nowego rekordu
	mov	rdi,	rdx

.not_at_end:
	; pobierz adres nestępnej części/strony serpentyny
	mov	rdi,	qword [rdi]

.in_page:
	; sprawdź czy rekord jest niedostepny
	cmp	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	VARIABLE_EMPTY
	jne	.next	; jeśli zajęty

.found:
	; pobierz dostępny identyfikator demona
	mov	rax,	qword [variable_multitasking_pid_value_next]

	; zachowaj numer aktualnego wolnego numeru PID
	push	rax

	; szukaj nastepnego wolnego
	inc	rax

	; zachowaj numer następnego wolnego numeru PID
	push	rax

	; sprawdź czy numer procesu jest dozwolony
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE
	xor	rdx,	rdx
	div	rcx

	; modulo ROZMIAR_STRONY != 0
	cmp	rdx,	VARIABLE_EMPTY
	jne	.pid

	; następny
	inc	qword [rsp]

.pid:
	; zapisz następny wolny numer PID
	pop	qword [variable_multitasking_pid_value_next]

	; przywróć numer procesu
	pop	rbx

	; powrót z procedury
	ret

.no_memory:
	; nie przydzielono numeru procesu, brak pamięci do rozszerzenia serpentyny
	mov	rbx,	VARIABLE_FALSE

	; powrót z procedury
	ret
