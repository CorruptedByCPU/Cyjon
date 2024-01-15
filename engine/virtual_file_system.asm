;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; struktura SuperBloku wirtualnego systemu plików jądra systemu
struc virtual_file_system_superblock
	.s_all_blocks_count	resq	1
	.s_fs_blocks_count	resq	1

	.s_knots_table		resq	1
	.s_knots_table_size	resq	1
endstruc

; SuperBlok
variable_virtual_file_system_superblock	times	4	dq	VARIABLE_EMPTY

; 64 bitowy kod programu
[BITS 64]

;===============================================================================
; tworzy strukture wirtualnego systemu plików
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
virtual_file_system:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; przygotuj miejsce na tablice supłów
	call	cyjon_page_allocate
	cmp	rdi,	VARIABLE_EMPTY
	ja	.ok

	; błąd krytyczny
	mov	rsi,	text_vfs_fail
	jmp	cyjon_screen_kernel_panic

.ok:
	; wyczyść
	call	cyjon_page_clear

	; aktualny rozmiar nośnika w blokach
	mov	qword [variable_virtual_file_system_superblock],	1	; tablica supłów

	; rozmair systemu plików w blokach
	mov	qword [variable_virtual_file_system_superblock + virtual_file_system_superblock.s_fs_blocks_count],	1

	; zapisz adres tablicy supłów
	mov	qword [variable_virtual_file_system_superblock + virtual_file_system_superblock.s_knots_table],	rdi

	; rozmiar tablicy supłów w blokach
	mov	qword [variable_virtual_file_system_superblock + virtual_file_system_superblock.s_knots_table_size],	1

	; wyświetl informację o utworzeniu wirtualnego systemu plików
	mov	bl,	VARIABLE_COLOR_LIGHT_GREEN
	mov	cl,	VARIABLE_FULL
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	bl,	VARIABLE_COLOR_DEFAULT
	mov	cl,	VARIABLE_FULL
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_vfs_ready
	call	cyjon_screen_print_string

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

;===============================================================================
; procedura zapisuje plik do wirtualnego systemu plików
; IN:
;	rcx - ilość znaków w nazwie pliku
;	rdx - rozmiar pliku w Bajtach
;	rdi - wskaźnik przechowywania pliku w pamięci
;	rsi - wskaźnik do nazwy pliku
;
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_virtual_file_system_save_file:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; sprawdź czy istnieje plik o podanej nazwie w katalogu głównym
	call	cyjon_virtual_file_system_find_file
	jnc	.no	; brak pliku, utwórz nowy wpis do katalogu głównego

	; aktualizuj nowy rozmiar pliku w rekordzie tablicy knotów
	mov	qword [rdi + 0x08],	rdx

	; kontynuuj zapis pliku
	jmp	.continue

.no:
	; szukaj wolnego rekordu w katalogu głównym
	call	cyjon_virtual_file_system_find_free_knot

	; zapisz rozmiar pliku w Bajtach
	mov	qword [rdi + 0x08],	rdx

	; zapisz ilość znaków przypadających na nazwę pliku
	mov	qword [rdi + 0x10],	rcx

	; zapamiętaj adres wskaźnika
	push	rdi

	; przesuń wskaźnik na nazwe pliku w rekordzie
	add	rdi,	0x18

	; zapisz do rekordu nazwe pliku
	rep	movsb

	; przywróć adres wskaźnika
	pop	rax

	; pobierz adres pierwszego wolnego bloku/strony
	call	cyjon_page_allocate
	cmp	rdi,	VARIABLE_EMPTY
	jne	.page0_ok

	; błąd krytyczny
	mov	rsi,	text_vfs_no_memory
	jmp	cyjon_screen_kernel_panic

.page0_ok:
	; ustaw na swoje miejsca
	xchg	rdi,	rax

	; zapisz do rekordu pierwszy blok danych zawartości pliku
	mov	qword [rdi],	rax

.continue:
	; załaduj adres przechowywanego pliku w pamięci
	mov	rsi,	qword [rsp]

	; załaduj numer pierwszego bloku danych pliku
	mov	rdi,	qword [rdi]

.save:
	; zachowaj adres przeznaczenia pliku
	push	rdi

	; sprawdź czy cały/pozostała część pliku mieści się w jednym bloku
	cmp	rdx,	4096 - 0x08
	jbe	.last_block

	; skopiuj część pliku do bloku danych
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE - 0x08
	; oblicz pozostałą część pliku do skopiowania
	sub	rdx,	rcx
	; koryguj o rozmiar
	shr	rcx,	3	; /8
	; kopiuj
	rep	movsq

	; sprawdź czy jest opisany następny blok do uzupełniania danymi pliku
	cmp	qword [rdi],	VARIABLE_EMPTY
	ja	.store

	; zachowaj adres bloku modyfikowanego
	push	rdi
	mov	rax,	rdi

	; zaalokuj następny blok pod dane pliku
	call	cyjon_page_allocate
	cmp	rdi,	VARIABLE_EMPTY
	jne	.page1_ok

	; błąd krytyczny
	mov	rsi,	text_vfs_no_memory
	jmp	cyjon_screen_kernel_panic

.page1_ok:

	; ustaw na swoje miejsca
	xchg	rdi,	rax

	; załaduj informacje do aktualnego bloku
	stosq

	; przyrwóć adres aktualnie modyfikowanego bloku
	pop	rdi

.store:
	; przywróć adres przeznaczenia pliku
	pop	rdi

	; załaduj numer następnego bloku do modyfikacji
	mov	rdi,	qword [rdi + VARIABLE_MEMORY_PAGE_SIZE - 0x08]

	; sprawdź czy koniec danych pliku
	cmp	rdx,	VARIABLE_EMPTY
	je	.end

	; kontynuuj z pozostałymi blokami
	jmp	.save

.last_block:
	; skopiuj pozostałą część pliku
	mov	rcx,	rdx
	; kopiuj
.copy:
	mov	al,	byte [rsi]
	mov	byte [rdi],	al
	add	rsi,	VARIABLE_INCREMENT
	add	rdi,	VARIABLE_INCREMENT
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.copy

	; uzupełnij o pustą przestrzeń
	xor	rax,	rax
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE
	sub	rcx,	rdx
	; wyczyść
	rep	stosb

	; koniec zawartości pliku
	xor	rdx,	rdx

	; kontynuuj zapis
	jmp	.store

.end:
	; sprawdzić czy pozostały jakieś bloku do zwolnienia, gdy plik zaaktualizowany jest mniejszy

	; przywróc oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax
	
	; powrót z procedury
	ret

;===============================================================================
; procedura wyszukuje w katalogu głównym wolnego supła/węzła dla pliku
; IN:
;	brak
;
; OUT:
;	rdi - adres bezwzględny znalezionego wolnego supła
;
; pozostałe rejestry zachowane
cyjon_virtual_file_system_find_free_knot:
	; zachowaj oryginalne rejestry
	push	rcx

	; załaduj adres poczatku tablicy supłów
	mov	rdi,	qword [variable_virtual_file_system_superblock + virtual_file_system_superblock.s_knots_table]

.prepare:
	; ilość rekordów na blok
	mov	rcx,	73

.loop:
	; sprawdź czy ilość znaków w nazwie pliku jest równa zero
	cmp	qword [rdi + 0x10],	VARIABLE_EMPTY
	je	.found

	; przesuń wskaźnik na następny rekord
	add	rdi,	56

	; kontynuuj z kolejnymi rekordami
	loop	.loop

	; sprawdź czy tablica zawiera inne bloki danych
	cmp	qword [rdi],	VARIABLE_EMPTY
	je	.new	; jeśli tak, przeszukaj następny blok

	; pobierz adres następnego bloku tablicy
	mov	rdi,	qword [rdi]

	; kontynuuj poszukiwania
	jmp	.prepare

.new:
	; zapamiętaj
	mov	rcx,	rdi

	; zarezerwuj wolny blok
	call	cyjon_page_allocate
	cmp	rdi,	VARIABLE_EMPTY
	jne	.page0_ok

	; błąd krytyczny
	mov	rsi,	text_vfs_no_memory
	jmp	cyjon_screen_kernel_panic

.page0_ok:
	; wyczyść
	call	cyjon_page_clear

	; dopisz do tablicy
	mov	qword [rcx],	rdi

	; kontynuuj poszukiwania
	jmp	.prepare
	
.found:
	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
; procedura ładuje zawartość pliku do pamięci
; IN:
;	rsi - numer pierwszego bloku danych pliku
;	rdi - adres gdzie załadować plik
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_virtual_file_system_read_file:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

.prepare:
	; rozmiar bloku do skopiowania
	mov	rcx,	4096 - 8
	shr	rcx,	3	; /8

	; kopiuj
	rep	movsq

	; sprawdź czy koniec pliku
	cmp	qword [rsi],	VARIABLE_EMPTY
	je	.end

	; pobierz informacje o następnym bloku do załadowania
	mov	rsi,	qword [rsi]

	; kontynuuj z następnym blokiem
	jmp	.prepare

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
; procedura przeszukuje katalog główny systemu plików za wskazaną nazwą pliku
; IN:
;	rcx - ilość znaków w nazwie pliku
;	rsi - ciąg znaków reprezentujący nazwę pliku
;
; OUT:
;	rdi - adres rekordu opisującego plik
;
; wszystkie rejestry zachowane
cyjon_virtual_file_system_find_file:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi
	push	rcx

	; zapamiętaj ilość znaków w nazwie pliku
	mov	rax,	rcx

	; wyzeruj numer rekordu

	; załaduj adres poczatku tablicy supłów
	mov	rdi,	qword [variable_virtual_file_system_superblock + virtual_file_system_superblock.s_knots_table]

.prepare:
	; ilość rekordów na blok
	mov	rcx,	73

.loop:
	; sprawdź czy ilość znaków na nazwe pliku jest różna poszukiwanej
	cmp	qword [rdi + 0x10],	rax
	jne	.continue

	; przesuń wskaźnik na ciąg znaków nazwy pliku
	add	rdi,	0x18

	; koryguj zawartość zmiennej
	xchg	rcx,	rax

	; porównaj ciągi
	call	library_compare_string

	; koryguj zawartość zmiennej
	xchg	rcx,	rax

	; czy ciągi były takie same?
	jnc	.found

	; koryguj wskaźnik na poczatek rekordu
	sub	rdi,	0x18

.continue:
	; przesuń wskaźnik na następny rekord
	add	rdi,	56

	; kontynuuj z kolejnymi rekordami
	loop	.loop

	; skończyły się rekordy z danego bloku
	mov	rdi,	qword [rdi]

	; sprawdź czy tablica zawiera inne bloki danych
	cmp	rdi,	VARIABLE_EMPTY
	ja	.prepare	; jeśli tak, przeszukaj następny blok

	; zwróć brak adresu rekordu szukanego pliku
	xor	rdi,	rdi

	; wyłącz flagę
	clc

	; koniec obsługi procedury
	jmp	.end
	
.found:
	; zwróć adres rekordu opisującego znleziony plik
	sub	rdi,	0x18

	; ustaw wlagę
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rsi
	pop	rax

	; powrót z procedury
	ret
