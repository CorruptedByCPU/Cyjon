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
; procedura/podprocedury obsługujące przerwanie programowe procesów
; IN:
;	różne
; OUT:
;	różne
;
; różne rejestry zachowane
irq64:
	; obsługa procesów?
	cmp	ah,	VARIABLE_KERNEL_SERVICE_PROCESS
	je	.process

	; obsługa ekranu?
	cmp	ah,	VARIABLE_KERNEL_SERVICE_SCREEN
	je	.screen

	; obsługa klawiatury?
	cmp	ah,	VARIABLE_KERNEL_SERVICE_KEYBOARD
	je	.keyboard

	; obsługa systemu?
	cmp	ah,	VARIABLE_KERNEL_SERVICE_SYSTEM
	je	.system

	; obsługa sieci?
	cmp	ah,	VARIABLE_KERNEL_SERVICE_NETWORK
	je	.network

	; obsługa wirtualnego systemu plików?
	cmp	ah,	VARIABLE_KERNEL_SERVICE_VFS
	je	.vfs

	; obsługa ekranu w trybie graficznym?
	cmp	ah,	VARIABLE_KERNEL_SERVICE_VIDEO
	je	.video

	; obsługa nośników danych?
	cmp	ah,	VARIABLE_KERNEL_SERVICE_DRIVE
	je	.drive

	; koniec obsługi przerwania programowego
	iretq

.process:
	; proces zakończył działanie?
	cmp	al,	VARIABLE_KERNEL_SERVICE_PROCESS_END
	je	irq64_process_end

	; uruchomić nowy proces?
	cmp	al,	VARIABLE_KERNEL_SERVICE_PROCESS_NEW
	je	irq64_process_new

	; sprawdzić czy proces jest uruchomiony?
	cmp	al,	VARIABLE_KERNEL_SERVICE_PROCESS_CHECK
	je	irq64_process_check

	; zaalokować przestrzeń dla procesu?
	cmp	al,	VARIABLE_KERNEL_SERVICE_PROCESS_MEMORY_ALLOCATE
	je	irq64_process_memory

	; pobrać listę procesów?
	cmp	al,	VARIABLE_KERNEL_SERVICE_PROCESS_LIST
	je	irq64_process_list

	; pobrać przesłane argumenty?
	cmp	al,	VARIABLE_KERNEL_SERVICE_PROCESS_ARGS
	je	irq64_process_args

	; pobrać własny numer PID?
	cmp	al,	VARIABLE_KERNEL_SERVICE_PROCESS_PID
	je	irq64_process_pid

	; zakończyć proces o podanym PID?
	cmp	al,	VARIABLE_KERNEL_SERVICE_PROCESS_KILL
	je	irq64_process_kill

	; koniec obsługi przerwania programowego
	iretq

.screen:
	; dostęp do procedur niezależnie od blokady przestrzeni pamięci ekranu

	; pobrać własności ekranu?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_SIZE
	je	irq64_screen_size

	; ukryć kursor?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_HIDE
	je	irq64_screen_cursor_hide

	; pokazać kursor?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SHOW
	je	irq64_screen_cursor_show

	; przestrzeń pamięci ekranu nie dostępna? ------------------------------
	cmp	byte [variable_screen_video_user_semaphore],	VARIABLE_TRUE
	je	.end

	; wyczyścić ekran?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CLEAN
	je	irq64_screen_clear

	; wyświetlić ciąg znaków?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	je	irq64_screen_print_string

	; wyświetlić znak?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	je	irq64_screen_print_char

	; wyświetlić liczbę/cyfrę?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	je	irq64_screen_print_number

	; pobrać pozycję kursora na ekranie?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_GET
	je	irq64_screen_cursor_get

	; ustawić kursor na ekranie?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	je	irq64_screen_cursor_set

	; przesunąć część ekranu?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_SCROLL
	je	irq64_screen_scroll

.end:
	; koniec obsługi przerwania programowego
	iretq

.keyboard:
	; pobierz kod klawisza z bufora klawiatury?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_KEYBOARD_GET_KEY
	je	irq64_keyboard_get_key

	; koniec obsługi przerwania programowego
	iretq

.system:
	; pobierz właściwości pamięci?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_SYSTEM_MEMORY
	je	irq64_system_memory

	; koniec obsługi przerwania programowego
	iretq

.network:
	; ustaw adres IP?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_NETWORK_IP_SET
	je	irq64_network_ip_set

	; pobierz adres IP?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_NETWORK_IP_GET
	je	irq64_network_ip_get

	; zarezerwuj port na interfejsie sieciowym?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_NETWORK_PORT_ASSIGN
	je	irq64_network_port_assign

	; zwolnij port na interfejsie sieciowym?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_NETWORK_PORT_RELEASE
	je	irq64_network_port_release

	; wyślij dane na podstawie identyfikatora połączenia?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_NETWORK_ANSWER
	je	irq64_network_answer

	; koniec obsługi przerwania programowego
	iretq

.vfs:
	; odczytać katalog główny wirtualnego systemu plików?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_VFS_DIR_ROOT
	je	irq64_vfs_dir_root

	; odczytać plik?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_VFS_FILE_READ
	je	irq64_vfs_file_read

	; zapisać plik?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_VFS_FILE_SAVE
	je	irq64_vfs_file_save

	; zaktualizować plik?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_VFS_FILE_UPDATE
	je	irq64_vfs_file_update

	; koniec obsługi przerwania programowego
	iretq

.video:
	; pobierz właściwości pamięci?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_VIDEO_INFO
	je	irq64_video_info

	; uzyskaj dostęp do przestrzeni pamięci ekranu?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_VIDEO_ACCESS
	je	irq64_video_access

	; koniec obsługi przerwania programowego
	iretq

.drive:
	; pobrać listę dostępnych nośników?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_DRIVE_LIST
	je	irq64_drive_list

	; odczytać sektor z nośnika?
	cmp	ax,	VARIABLE_KERNEL_SERVICE_DRIVE_SECTOR_READ
	je	irq64_drive_sector_read

	; koniec obsługi przerwania programowego
	iretq

;===============================================================================
;===============================================================================
irq64_process_end:
	; zatrzymaj aktualnie uruchomiony proces
	mov	rdi,	qword [variable_multitasking_serpentine_record_active_address]

.prepared:
	; ustaw flagę "proces zakończony", "rekord nieaktywny"
	and	byte [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	~STATIC_SERPENTINE_RECORD_FLAG_ACTIVE
	or	byte [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	STATIC_SERPENTINE_RECORD_FLAG_CLOSED

	; zakończ obsługę procesu
	hlt

	; zatrzymaj dalsze wykonywanie kodu procesu, jeśli coś poszło nie tak??
	jmp	$

;-------------------------------------------------------------------------------
irq64_process_new:
	; uruchom nowy proces
	call	cyjon_process_init

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_process_check:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rdi

	; pobierz numer PID procesu do sprawdzenia
	mov	rax,	rcx

	; załaduj adres początku serpentyny
	mov	rdi,	qword [variable_multitasking_serpentine_start_address]

	; ustal ilość rekordów na jedną stronę w serpentynie
	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_QWORD_SIZE ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE
	; pobierz ilość rekordów w serpentynie
	mov	rdx,	qword [variable_multitasking_serpentine_record_counter]

	; kontynuuj
	jmp	.continue

.next_record:
	; zmniejsz ilość rekordów sprawdzonych w aktualnej stronie
	dec	rcx
	; zmniejsz ilość rekordów sprawdzonych w serpentynie
	dec	rdx

	; przesuń wskaźnik adresu na następny rekord
	add	rdi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.continue:
	; koniec rekordów w serpentynie? brak uruchomionego procesu o podanym PID
	cmp	rdx,	VARIABLE_EMPTY
	ja	.left_something

	; brak uruchomionego procesu o danym PID
	xor	rcx,	rcx

	; koniec
	jmp	.end

.left_something:
	; koniec rekordów na stronie serpentyny? sprawdź następną stronę
	cmp	rcx,	VARIABLE_EMPTY
	ja	.in_page

	; pobierz adres natęnej strony serpentyny
	and	di,	VARIABLE_MEMORY_PAGE_ALIGN
	mov	rdi,	qword [rdi + VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_QWORD_SIZE]

	; zresetuj licznik rekordów na stronę w serpentynie
	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_QWORD_SIZE ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.in_page:
	; rekord zawiera numer PID poszukiwanego procesu?
	cmp	rax,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.PID]
	jne	.next_record

	; zwróć numer PID poszukiwanego procesu - proces istnieje
	mov	rcx,	rax

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rbx
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_process_memory:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	r11

	; przygotuj przestrzeń pamięci
	mov	rax,	rdi
	mov	rdi,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rax,	rdi
	mov	rbx,	VARIABLE_MEMORY_PAGE_FLAG_AVAILABLE + VARIABLE_MEMORY_PAGE_FLAG_WRITE + VARIABLE_MEMORY_PAGE_FLAG_USER
	mov	r11,	cr3
	call	cyjon_page_map_logical_area

	; przywóć oryginalne rejestry
	pop	r11
	pop	rdi

	; wyczyść przestrzeń
	call	cyjon_page_clear_few

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rbx
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_process_list:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r8
	push	r11
	push	rdi

	; sprawdź czy proces prosi o utworzenie tablicy w miejscu dozwolonym
	mov	rax,	VARIABLE_MEMORY_HIGH_REAL_ADDRESS
	cmp	rdi,	rax
	jb	.error

	; pobierz ilość rekordów w serpentynie
	mov	rax,	qword [variable_multitasking_serpentine_record_counter]
	; pobierz rozmiar jednego rekordu
	mov	rcx,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE
	xor	rdx,	rdx	; wyczyść starszą część
	; oblicz rozmiar przestrzeni wymagany do exportu tablicy
	mul	rcx

	; zamień na strony
	shr	rax,	VARIABLE_DIVIDE_BY_4096	; VARIABLE_MEMORY_PAGE_SIZE

	; zwiększ o jedną, jeśli proces prosi o utworzenie tablicy nie od pełnego adresu tj. 0xF000
	inc	rax
	mov	rcx,	rax	; załaduj do licznika

	; zachowaj adres docelowy tablicy
	push	rdi

	; przygotuj miejsce pod tablicę w przestrzeni porocesu
	mov	rax,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rdi,	rax
	and	di,	VARIABLE_MEMORY_PAGE_ALIGN	; wyrównaj adres do pełnej strony
	mov	rax,	rdi	; ustaw na swoje miejsce - rax => adres
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	r11,	cr3
	call	cyjon_page_map_logical_area

	; przywróć adres docelowy tablicy
	pop	rdi

	; ilość rekordów na stronę
	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_QWORD_SIZE ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE
	; początek tablicy serpentyny
	mov	rsi,	qword [variable_multitasking_serpentine_start_address]

	; ropocznij przeglądanie
	jmp	.page

.empty:
	; przesuń wskaźnik na następny rekord
	add	rsi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.record:
	; zmniejsz ilość rekordów w stronie
	dec	rcx

.page:
	; sprawdź zostały rekordy w stronie
	cmp	rcx,	VARIABLE_EMPTY
	ja	.in_page

	; pobierz adres następnej strony/części serpentyny
	and	si,	VARIABLE_MEMORY_PAGE_ALIGN
	mov	rsi,	qword [rsi + VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_QWORD_SIZE]

	; sprawdź czy istnieje dalsza część serpentyny
	cmp	rsi,	qword [variable_multitasking_serpentine_start_address]
	je	.terminate	; koniec

	; zresetuj ilość rekordów na stronę
	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_QWORD_SIZE ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.in_page:
	; sprawdź czy rekord pusty
	cmp	qword [rsi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	VARIABLE_EMPTY	
	je	.empty

	; zachowaj licznik
	push	rcx

	; skopiuj rekord do tablicy procesu
	mov	rcx,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE
	rep	movsb

	; usuń informacje o PML4 rekordu
	mov	qword [rdi - VARIABLE_TABLE_SERPENTINE_RECORD.SIZE + VARIABLE_TABLE_SERPENTINE_RECORD.CR3],	VARIABLE_EMPTY
	; usuń informacje o stosie
	mov	qword [rdi - VARIABLE_TABLE_SERPENTINE_RECORD.SIZE + VARIABLE_TABLE_SERPENTINE_RECORD.RSP],	VARIABLE_EMPTY

	; przywróć licznik
	pop	rcx

	; kontynuuj przeglądanie
	jmp	.record

.terminate:
	; pusty rekord na koniec tablicy
	stosq
	stosq

	; koniec
	jmp	.end

.error:
	; nieprawidłowy adres, anulowano
	mov	qword [rsp],	VARIABLE_EMPTY

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	r11
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_process_args:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r11

	; pobierz rozmiar ciągu argumentów przesłanych do procesu
	mov	rdi,	qword [variable_multitasking_serpentine_record_active_address]
	mov	rcx,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.ARGS]
	cmp	rcx,	VARIABLE_EMPTY
	je	.end	; brak argumentów przesłanych do procesu

	; przygotuj miejsce pod argumenty
	mov	rax,	qword [rsp + VARIABLE_QWORD_SIZE * 0x02]
	mov	rbx,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rax,	rbx
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	rcx,	1	; rozmiar 1 strona
	mov	r11,	cr3
	call	cyjon_page_map_logical_area

	mov	rsi,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.ARGS]
	mov	rdi,	qword [rsp + VARIABLE_QWORD_SIZE * 0x02]

	; zachowaj rozmiar ciągu argumentów
	push	qword [rsi]

	; przesuń wskaźnik na początek ciągu
	add	rsi,	VARIABLE_QWORD_SIZE

	; skopiuj ciąg argumentów do pamięci procesu
	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_QWORD_SIZE ) / VARIABLE_QWORD_SIZE
	rep	movsq

	; przywróć rozmiar ciągu argumentów
	pop	rcx

.end:
	; przywróć oryginalne rejestry
	pop	r11
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rbx
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_process_pid:
	; zachowaj oryginalne rejestry
	push	rsi

	; załaduj własny adres rekordu
	mov	rsi,	qword [variable_multitasking_serpentine_record_active_address]
	; pobierz numer PID
	mov	rcx,	qword [rsi + VARIABLE_TABLE_SERPENTINE_RECORD.PID]

	; przywróć oryginalne rejestry
	pop	rsi

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_process_kill:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdi

	; ktoś chce ubić jądro systemu? good luck
	cmp	rcx,	VARIABLE_EMPTY
	je	.easter_egg

	; ustaw wskaźnik na początek serpentyny
	mov	rdi,	qword [variable_multitasking_serpentine_start_address]

	; ustaw liczniki
	mov	rbx,	( VARIABLE_MEMORY_PAGE_SIZE - 0x08 ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

	; sprawdź pierwszy rekord
	jmp	.check

.continue:
	; mniejsz ilość rekordów do przeszukania w tej części serpentyny
	dec	rbx
	jnz	.check

	; załaduj adres kontynuacji serpentyny
	and	di,	0xF000
	mov	rdi,	qword [rdi + VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_QWORD_SIZE]

	; wróciliśmy do początku?
	cmp	rdi,	qword [variable_multitasking_serpentine_start_address]
	je	.lost

	; zresetuj licznik rekordów na stronę
	mov	rbx,	( VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_QWORD_SIZE ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.check:
	; sprawdź PID procesu (rekordu)
	cmp	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.PID],	rcx
	je	.found

	; przesuń wskaźnik na następny rekord
	add	rdi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

	; sprawdź pozostałe rekordy
	jmp	.continue

.found:
	; sprawdź czy użytkownik chce zabić demona
	mov	bx,	STATIC_SERPENTINE_RECORD_BIT_DAEMON
	bt	word [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	bx
	jc	.prohibited_operation

	; ustaw flagę rekordu "proces zakończony", "rekord nieaktywny"
	and	byte [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	~STATIC_SERPENTINE_RECORD_FLAG_ACTIVE
	or	byte [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	STATIC_SERPENTINE_RECORD_FLAG_CLOSED

	; proces zostanie zamknięty
	jmp	.end

.lost:
	; nie znaleziono podanej PID procesu w tablicy serpentyny
	xor	rcx,	rcx	; zwróć informacje o tym

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rbx

	; koniec obsługi przerwania programowego
	iretq

.prohibited_operation:
	; wyświetl ostrzeżenie
	mov	bl,	VARIABLE_COLOR_RED
	mov	cl,	VARIABLE_FULL
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_process_prohibited_operation
	call	cyjon_screen_print_string

	; zniszcz proces
	mov	rdi,	qword [variable_multitasking_serpentine_record_active_address]
	jmp	irq64_process_end.prepared

.easter_egg:
	; wymyśli się coś ciekawego
	cli

	jmp	$

;===============================================================================
;===============================================================================
irq64_screen_clear:
	; wyczyść ekran
	call	cyjon_screen_clear

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_screen_print_string:
	; wyświetl ciąg znaków na ekranie
	call	cyjon_screen_print_string

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_screen_print_char:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; wyłącz kursor
	call	cyjon_screen_cursor_lock

	; załaduj znak do wyświetlenia
	mov	rax,	r8
	
	; pobierz pozycje kursora w przestrzeni pamięci ekranu
	mov	rdi,	qword [variable_screen_cursor_indicator]

	; wyświetl znak
	call	cyjon_screen_print_char

	; zapisz aktualną pozycję kursora w przestrzeni pamięci ekranu
	mov	qword [variable_screen_cursor_indicator],	rdi

	; sprawdź pozycję wirtualnego kursora
	call	cyjon_screen_cursor_virtual

	; przesuń kursor na odpowiednią pozycję
	call	cyjon_screen_cursor_move

	; włacz kursor
	call	cyjon_screen_cursor_unlock

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_screen_print_number:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi

	; załaduj liczbe do wyświetlenia
	mov	rax,	r8

	; wyłącz kursor
	call	cyjon_screen_cursor_lock

	; wykonaj
	call	cyjon_screen_print_number

	; sprawdź pozycję wirtualnego kursora
	call	cyjon_screen_cursor_virtual

	; włącz kursor
	call	cyjon_screen_cursor_unlock

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_screen_cursor_get:
	; pozycja wirtualnego kursora
	mov	rbx,	qword [variable_screen_cursor]

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_screen_cursor_set:
	; zachowaj oryginalny rejestr
	push	rdi

	; tryb graficzny?
	cmp	byte [variable_screen_video_mode_semaphore],	VARIABLE_TRUE
	je	.graphics

	; zapisz pozycję kursora
	mov	qword [variable_screen_cursor],	rbx

	; oblicz nowy wskaźnik w przestrzeni ekranu
	call	cyjon_screen_cursor_indicator

	; przywróć oryginalny rejestr
	pop	rdi

	; przesuń kursor na wskazaną pozycję
	call	cyjon_screen_cursor_move

.end:
	; koniec obsługi przerwania programowego
	iretq	

.graphics:
	; wyłącz kursor
	call	cyjon_screen_cursor_lock

	; ustaw wirtualny kursor
	mov	qword [variable_screen_cursor],	rbx

	; generuj wskaźnik kursora w przestrzeni pamięci
	call	cyjon_screen_cursor_virtual

	; włącz kursor
	call	cyjon_screen_cursor_unlock

	; przywróć oryginalne rejestry
	pop	rdi

	; koniec
	jmp	.end

;-------------------------------------------------------------------------------
irq64_screen_size:
	; ilość wierszy w starszej części rejestru
	mov	rbx,	qword [variable_screen_height_on_chars]
	shl	rbx,	VARIABLE_MOVE_RAX_DWORD_LEFT
	; ilość kolumn w młodszej części
	or	rbx,	qword [variable_screen_width_on_chars]

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_screen_cursor_hide:
	call	cyjon_screen_cursor_lock

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_screen_cursor_show:
	call	cyjon_screen_cursor_unlock

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_screen_scroll:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; wyłącz kursor
	call	cyjon_screen_cursor_lock

	; wskaźnik początku pamięci przestrzeni ekranu
	mov	rsi,	qword [variable_screen_base_address]

	; oblicz adres lini źródłowej
	mov	rax,	qword [variable_screen_line_of_chars_in_bytes]
	mul	rdx

	; ustaw/przesuń wskaźnik 
	add	rsi,	rax

	; oblicz rozmiar przestrzemi pamięci do przesunięcia
	mov	rax,	qword [variable_screen_line_of_chars_in_bytes]
	xor	rdx,	rdx
	mul	rcx

	; ustaw licznik
	mov	rcx,	rax

	; kierunek przesunięcia?
	cmp	rbx,	VARIABLE_EMPTY
	je	.up

	; modyfikuj wskaźniki
	mov	rdi,	rsi
	add	rdi,	rcx
	add	rsi,	rcx
	sub	rsi,	qword [variable_screen_line_of_chars_in_bytes]

	shr	rcx,	VARIABLE_DIVIDE_BY_8

.loop:
	; przenieś
	mov	rax,	qword [rsi]
	mov	qword [rdi],	rax
	sub	rsi,	VARIABLE_QWORD_SIZE
	sub	rdi,	VARIABLE_QWORD_SIZE
	loop	.loop

	; koniec
	jmp	.end

.up:
	; ustaw wskaźnik docelowy
	mov	rdi,	rsi
	sub	rdi,	qword [variable_screen_line_of_chars_in_bytes]

	; przenieś
	shr	rcx,	VARIABLE_DIVIDE_BY_8
	rep	movsq

	; domyślny kolor tła
	mov	rax,	VARIABLE_COLOR_BACKGROUND_DEFAULT >> VARIABLE_SHIFT_BY_4
	mov	eax,	dword [table_color_palette_32_bit + rax * VARIABLE_DWORD_SIZE]

	; wyczyść ostatnią linię
	shr	rcx,	VARIABLE_DIVIDE_BY_4
	rep	stosd

.end:
	; wyświetl kursor
	call	cyjon_screen_cursor_unlock

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

;===============================================================================
;===============================================================================
irq64_keyboard_get_key:
	; pobierz kod ASCII klawisza z bufora klawiatury
	call	cyjon_keyboard_key_read

	; koniec obsługi przerwania programowego
	iretq

;===============================================================================
;===============================================================================
irq64_system_memory:
	mov	r11,	qword [variable_binary_memory_map_total]
	mov	r12,	qword [variable_binary_memory_map_free]
	mov	r13,	qword [variable_binary_memory_map_paged]
	mov	r14,	qword [variable_binary_memory_map_cached]
	mov	r15,	qword [variable_binary_memory_map_reserved]

	; koniec obsługi przerwania programowego
	iretq

;===============================================================================
;===============================================================================
irq64_network_ip_set:
	; ustaw adres IP
	mov	dword [variable_network_ip],	ebx

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_network_ip_get:
	; pobierz adres IP
	mov	ebx,	dword [variable_network_ip]

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_network_port_assign:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rdi

	; oblicz przesunięcie rekordu w tablicy
	mov	rax,	STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.SIZE
	xor	rdx,	rdx
	mul	rcx

	; sprawdź rekord tablicy portów
	mov	rdi,	qword [variable_daemon_tcp_ip_stack_table_port]
	cmp	qword [rdi + rax + STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.cr3],	VARIABLE_EMPTY
	ja	.not_free	; port zajęty

	; konfiguruj rekord
	add	rdi,	rax

	; CR3 procesu
	mov	rax,	cr3
	stosq

	; rozmiar przestrzeni
	mov	rax,	qword [rsp + VARIABLE_QWORD_SIZE]
	stosq

	; wskaźnik przestrzeni pamięci, gdzie składować dane dla procesu
	mov	rax,	qword [rsp]
	stosq

	; port zarezerwowany
	jmp	.end

.not_free:
	; zwróć kod błędu w rcx, port zajęty
	xor	rcx,	rcx

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_network_port_release:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rdi

	; oblicz przesunięcie rekordu w tablicy
	mov	rax,	STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.SIZE
	xor	rdx,	rdx
	mul	rcx

	; sprawdź rekord tablicy portów
	mov	rdi,	qword [variable_daemon_tcp_ip_stack_table_port]
	cmp	qword [rdi + rax + STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.cr3],	VARIABLE_EMPTY
	je	.end	; port wolny?

	; sprawdź czy proces jest właścicielem portu!
	mov	rcx,	cr3
	cmp	qword [rdi + rax + STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.cr3],	rcx
	jne	.prohibited_operation

	; zwolnij rekord
	mov	qword [rdi + rax + STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.cr3],	VARIABLE_EMPTY

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; koniec obsługi przerwania programowego
	iretq	

.prohibited_operation:
	; wyświetl ostrzeżenie
	mov	bl,	VARIABLE_COLOR_RED
	mov	cl,	VARIABLE_FULL
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_process_prohibited_operation
	call	cyjon_screen_print_string

	; zniszcz proces
	mov	rdi,	qword [variable_multitasking_serpentine_record_active_address]
	jmp	irq64_process_end.prepared

;-------------------------------------------------------------------------------
irq64_network_answer:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rsi
	push	rdi
	push	rcx

.restart:
	; rozmiar bufora wyjściowego stosu TCP/IP w rekordach
	mov	rcx,	VARIABLE_DAEMON_TCP_IP_STACK_CACHE_SIZE

	; ustaw wskaźnik do bufora wyjściowego stosu TCP/IP
	mov	rdi,	qword [variable_daemon_tcp_ip_stack_cache_out]

.search:
	; szukaj wolnego rekordu
	cmp	qword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.flag],	VARIABLE_DAEMON_TCP_IP_STACK_CACHE_FLAG_EMPTY
	je	.found

	; następny rekord w buforze stosu TCP/IP
	add	rdi,	STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.SIZE

	; szukaj dalej
	loop	.search

	; nie znaleziono wolnego rekordu, zacznij od początku
	jmp	.restart

.found:
	; zachowaj wskaźnik do rekordu
	push	rdi

	; zablokuj rekord
	mov	byte [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.flag],	VARIABLE_TRUE

	; załaduj do rekordu rozmiar danych do wysłania
	mov	rcx,	qword [rsp + VARIABLE_QWORD_SIZE]
	mov	qword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.size],	rcx

	; skopiuj dane
	add	rdi,	STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.data
	rep	movsb

	; przywróć wskaźnik do rekordu
	pop	rdi

	; aktywuj rekord, ustawiając numer identyfikatora połączenia na stosie TCP/IP
	mov	qword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.id],	rbx

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rbx

	; koniec obsługi przerwania programowego
	iretq

;===============================================================================
;===============================================================================
irq64_vfs_dir_root:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi
	push	r8
	push	r11

	; sprawdź czy proces prosi o załadowanie zawartości katalogu głównego w dozwolone miejsce
	mov	rax,	VARIABLE_MEMORY_HIGH_REAL_ADDRESS
	cmp	rdi,	rax
	jb	.error

	; wyrównaj adres do pełnej strony
	and	di,	VARIABLE_MEMORY_PAGE_ALIGN
	cmp	rdi,	qword [rsp + VARIABLE_QWORD_SIZE * 0x02]
	je	.aligned

	; przesuń wskaźnik na następną stronę
	add	rdi,	VARIABLE_MEMORY_PAGE_SIZE

	; aktualizuj adres na stosie
	mov	qword [rsp + VARIABLE_QWORD_SIZE * 0x02],	rdi

.aligned:
	; pobierz pozycję surperbloku wirtualnego systemu plików
	mov	rsi,	variable_vfs_superblock

	; pobierz rozmiar katalogu głównego w blokach
	mov	rcx,	qword [rsi + STRUCTURE_VFS_SUPERBLOCK.size]

	; zachowaj adres docelowy
	push	rdi

	; przygotuj miejsce pod tablicę w przestrzeni procesu
	mov	rax,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rdi,	rax
	mov	rax,	rdi	; ustaw na swoje miejsce - rax => adres
	mov	rbx,	VARIABLE_MEMORY_PAGE_FLAG_AVAILABLE + VARIABLE_MEMORY_PAGE_FLAG_WRITE + VARIABLE_MEMORY_PAGE_FLAG_USER
	mov	r11,	cr3
	call	cyjon_page_map_logical_area

	; przywróć adres docelowy
	pop	rdi

	; ustaw wskaźnik na początek tablicy supłów
	mov	rsi,	qword [rsi + STRUCTURE_VFS_SUPERBLOCK.root]

	; wyczyść rozmiar katalogu głównego w Bajtach
	xor	rdx,	rdx

.restart:
	; ilość rekordów na blok danych katalogu głównego
	mov	rcx,	STRUCTURE_VFS_BLOCK.SIZE - VARIABLE_QWORD_SIZE
	add	rdx,	rcx	; oblicz rozmiar katalogu głównego w Bajtach
	; kopiuj do procesu
	rep	movsb

	; określ adres kolejnego bloku danych katalogu głównego
	and	si,	VARIABLE_MEMORY_PAGE_ALIGN
	mov	rsi,	qword [rsi + STRUCTURE_VFS_BLOCK.link]
	cmp	rsi,	VARIABLE_EMPTY
	jne	.restart

.end:
	; przywróć oryginalne rejestry
	pop	r11
	pop	r8
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

.error:
	; błąd adresu docelowego
	xor	rdi,	rdi

	; koniec
	jmp	.end

;-------------------------------------------------------------------------------
irq64_vfs_file_read:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	r8
	push	r11
	push	rdi

	; sprawdź czy proces prosi o załadowanie zawartości katalogu głównego w dozwolone miejsce
	mov	rax,	VARIABLE_MEMORY_HIGH_REAL_ADDRESS
	cmp	rdi,	rax
	jb	.error

	; wyrównaj adres do pełnej strony
	and	di,	VARIABLE_MEMORY_PAGE_ALIGN
	cmp	rdi,	qword [rsp]
	je	.aligned

	; przesuń wskaźnik na następną stronę
	add	rdi,	VARIABLE_MEMORY_PAGE_SIZE

	; aktualizuj adres na stosie
	mov	qword [rsp],	rdi

.aligned:
	; szukaj pliku w wirtualnym systemie plików
	call	cyjon_vfs_file_find
	jc	.no_file

	; zwróć identyfikator pliku
	mov	rdx,	rdi

	; pobierz rozmiar pliku
	mov	rcx,	qword [rdi + STRUCTURE_VFS_KNOT.size]
	push	rcx	; zapamiętaj

	; oblicz rozmiar pliku w stronach
	and	cx,	VARIABLE_MEMORY_PAGE_ALIGN
	cmp	rcx,	qword [rdi + STRUCTURE_VFS_KNOT.size]
	je	.size_ok

	; istnieje reszta z dzielenia
	add	rcx,	VARIABLE_MEMORY_PAGE_SIZE

.size_ok:
	; zamień na ilość stron
	shr	rcx,	VARIABLE_MEMORY_PAGE_SIZE_IN_BITS

	; pobierz identyfikator pierwszego bloku danych pliku
	mov	rsi,	qword [rdi + STRUCTURE_VFS_KNOT.id]

	; plik zapisz w miejscu docelowym procesu
	mov	rdi,	qword [rsp + VARIABLE_QWORD_SIZE]

	; zachowaj wskaźnik docelowy
	push	rdi

	; przygotuj miejsce pod wczytywany plik w przestrzeni procesu
	mov	rax,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rdi,	rax
	mov	rax,	rdi	; ustaw na swoje miejsce - rax => adres
	mov	rbx,	VARIABLE_MEMORY_PAGE_FLAG_AVAILABLE + VARIABLE_MEMORY_PAGE_FLAG_WRITE + VARIABLE_MEMORY_PAGE_FLAG_USER
	mov	r11,	cr3
	call	cyjon_page_map_logical_area

	; przywróć wskaźnik docelowy
	pop	rdi

	; przywróć rozmiar pliku w Bajtach
	pop	rcx

	; załaduj plik do pamięci procesu
	call	cyjon_vfs_file_read

	; zwróć rozmiar do procesu
	mov	qword [rsp + VARIABLE_QWORD_SIZE * 0x04],	rcx

	; brak błędu
	mov	qword [rsp + VARIABLE_QWORD_SIZE * 0x05],	VARIABLE_EMPTY

	; koniec
	jmp	.end

.no_file:
	; pliku nie znaleziono
	mov	qword [rsp + VARIABLE_QWORD_SIZE * 0x05],	VARIABLE_VFS_ERROR_FILE_NOT_EXISTS

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	r11
	pop	r8
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

.error:
	; błąd adresu docelowego
	mov	qword [rsp],	VARIABLE_EMPTY

	; koniec
	jmp	.end

;-------------------------------------------------------------------------------
irq64_vfs_file_save:
	; zapisz plik
	call	cyjon_vfs_file_save

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_vfs_file_update:
	; koniec obsługi przerwania programowego
	iretq

;===============================================================================
;===============================================================================
irq64_video_info:
	mov	rbx,	qword [variable_screen_base_address]
	mov	rcx,	qword [variable_screen_size]
	mov	rdx,	qword [variable_screen_width_scan_line]
	mov	r8,	qword [variable_screen_width]
	mov	r9,	qword [variable_screen_height]

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_video_access:
	; zachowaj oryginalne rejestry
	push	rax

	; sprawdź czy inny proces ma już dostęp do przestrzeni pamięci ekranu
	cmp	byte [variable_screen_video_user_semaphore],	VARIABLE_TRUE
	je	.false	; zignoruj

	; zablokuj dostęp do pamięci przestrzeni ekranu dla innych procesów
	mov	byte [variable_screen_video_user_semaphore],	VARIABLE_TRUE

	; zezwól procesowi na dostęp do przestrzeni pamięci ekranu
	mov	rax,	cr3
	mov	bl,	byte [rax]
	add	bl,	VARIABLE_MEMORY_PAGE_FLAG_USER
	mov	byte [rax],	bl

	; włącz flagę w rekordzie serpentyny procesu
	mov	rax,	qword [variable_multitasking_serpentine_record_active_address]
	bts	qword [rax],	STATIC_SERPENTINE_RECORD_BIT_DESKTOP

	; dostęp udzielony
	xor	rbx,	rbx

	; koniec
	jmp	.end

.false:
	; brak dostępu
	mov	rbx,	VARIABLE_SCREEN_VIDEO_ERROR_ACCESS_DENIED

.end:
	; przywróć oryginalne rejestry
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

;===============================================================================
;===============================================================================
irq64_drive_list:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; sprawdź czy proces prosi o utworzenie tablicy w miejscu dozwolonym
	mov	rax,	VARIABLE_MEMORY_HIGH_REAL_ADDRESS
	cmp	rdi,	rax
	jb	.error

	; wyrównaj adres do pełnej strony
	and	di,	VARIABLE_MEMORY_PAGE_ALIGN
	cmp	rdi,	qword [rsp]
	je	.aligned

	; przesuń wskaźnik na następną stronę
	add	rdi,	VARIABLE_MEMORY_PAGE_SIZE

	; aktualizuj adres na stosie
	mov	qword [rsp],	rdi

.aligned:
	; obsługa tylko dysków ATA, rozmiar maksymalny 4 KiB
	mov	rcx,	1	; przyznaj rozmiar 4 KiB

	; przygotuj miejsce pod tablicę w przestrzeni porocesu
	mov	rax,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rdi,	rax
	mov	rax,	rdi	; ustaw na swoje miejsce - rax => adres
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	r11,	cr3
	call	cyjon_page_map_logical_area

	; kopiuj tablicę dostępnych dysków
	mov	rcx,	STRUCTURE_IDE_DISK * 4	; * maksymalna ilość dysków ATA
	mov	rsi,	variable_ide_disks
	rep	movsb

	; koniec
	jmp	.end

.error:
	; błędny wskaźnik adresu do przechowania tablicy dysków
	mov	qword [rsp],	VARIABLE_EMPTY

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

;-------------------------------------------------------------------------------
irq64_drive_sector_read:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

.daemon:
	; szukaj wolnego miejsca w buforze
	mov	rsi,	qword [variable_daemon_ide_io_cache]
	cmp	rsi,	VARIABLE_EMPTY
	je	.daemon	; bufor nie gotowy

.restart:
	; ilość możliwych rekordów w buforze
	mov	rcx,	VARIABLE_DAEMON_IDE_IO_CACHE_SIZE * VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_DAEMON_IDE_IO_CACHE.SIZE

.search:
	; sprawdź rekord
	cmp	byte [rsi],	VARIABLE_DAEMON_IDE_IO_CACHE_STATUS_FREE
	je	.found

	; przesuń wskaźnik na następny rekord
	add	rsi,	STRUCTURE_DAEMON_IDE_IO_CACHE.SIZE
	loop	.search

	; brak wolnych poleceń w buforze, szukaj od początku
	mov	rsi,	qword [variable_daemon_ide_io_cache]

	; kontynuuj
	jmp	.restart

.found:
	; zachowaj wskaźnik rekordu i licznik
	push	rcx
	push	rdi

	; zarezerwuj dostęp do rekordu
	mov	byte [rsi + STRUCTURE_DAEMON_IDE_IO_CACHE.status], VARIABLE_DAEMON_IDE_IO_CACHE_STATUS_RESERVED

	; ustaw nośnik do odczytu
	mov	byte [rsi + STRUCTURE_DAEMON_IDE_IO_CACHE.device],	bl
	; ustaw numer sektora do odczytu
	mov	rcx,	qword [rsp + VARIABLE_QWORD_SIZE * 0x04]
	mov	qword [rsi + STRUCTURE_DAEMON_IDE_IO_CACHE.lba],	rcx
	; wyczyść kod błedu
	mov	byte [rsi + STRUCTURE_DAEMON_IDE_IO_CACHE.error],	VARIABLE_EMPTY

	; pobierz numer PID procesu wykonującego akcje odczytu z nośnika
	mov	rcx,	qword [variable_multitasking_serpentine_record_active_address]
	mov	rcx,	qword [rsi + VARIABLE_TABLE_SERPENTINE_RECORD.PID]
	; ustaw numer PID procesu
	mov	qword [rsi + STRUCTURE_DAEMON_IDE_IO_CACHE.pid],	rcx

	; rekord przygotowany wywołaj operację
	mov	byte [rsi + STRUCTURE_DAEMON_IDE_IO_CACHE.status],	VARIABLE_DAEMON_IDE_IO_CACHE_STATUS_PREPARED

.wait:
	; zwolnij procesor
	hlt

	; czekaj na odpowiedź
	cmp	byte [rsi + STRUCTURE_DAEMON_IDE_IO_CACHE.status],	VARIABLE_DAEMON_IDE_IO_CACHE_STATUS_READY
	jne	.wait

	; przesuń wskaźnik na dane odpowiedzi
	add	rsi,	STRUCTURE_DAEMON_IDE_IO_CACHE.data
	mov	rcx,	qword [variable_ide_sector_size]
	; skopiuj odpowiedź do procesu
	rep	movsb

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; koniec obsługi przerwania programowego
	iretq
