;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; SuperBlok
variable_vfs_superblock	dq	VARIABLE_EMPTY
			dq	1	; *4096 domyślny rozmiar katalogu głównego

; struktura SuperBloku wirtualnego systemu plików jądra systemu
struc STRUCTURE_VFS_SUPERBLOCK
	.root	resq	1
	.size	resq	1
endstruc

; struktura supła w drzewie katalogu głównego
struc STRUCTURE_VFS_KNOT
	.id		resq	1
	.permission	resq	1
	.size		resq	1
	.chars		resq	1
	.name		resb	32	; ilość znaków na nazwę pliku
	.SIZE		resb	1	; rozmiar struktury w Bajtach
endstruc

; struktura bloku danych
struc STRUCTURE_VFS_BLOCK
	.data	resb	VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_QWORD_SIZE
	.link	resb	8	; wskaźnik do następnego bloku danych
	.SIZE	resb	1	; rozmiar struktury w Bajtach
endstruc

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
vfs:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; błąd krytyczny
	mov	rsi,	text_vfs_fail

	; przygotuj miejsce na tablice supłów
	call	cyjon_page_allocate
	jc	cyjon_screen_kernel_panic

	; wyczyść
	call	cyjon_page_clear

	; zapisz adres katalogu głównego i jego rozmiar
	mov	qword [variable_vfs_superblock + STRUCTURE_VFS_SUPERBLOCK.root],	rdi

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
;	rbx - uprawnienia do pliku
;	rcx - ilość znaków w nazwie pliku
;	rdx - rozmiar pliku w Bajtach
;	rsi - wskaźnik do nazwy pliku
;	rdi - wskaźnik przechowywania pliku w pamięci
;
; OUT:
;	rbx - kod błędu, ZERO jeśli ok
;		0x01 - plik istnieje
;		0x02 - brak wolnego miejsca
;
; wszystkie rejestry zachowane
cyjon_vfs_file_save:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9

	; flaga, błąd
	stc

	; kod błędu, nazwa pliku za długa
	mov	rbx,	VARIABLE_VFS_ERROR_NAME_TO_LONG

	; sprawdź obsługiwaną długość nazwy pliku
	mov	r8,	STRUCTURE_VFS_KNOT.SIZE - STRUCTURE_VFS_KNOT.name
	cmp	r8,	rcx
	jb	.end	; za długa nazwa pliku

	; kod błędu, nazwa pliku za krótka
	mov	rbx,	VARIABLE_VFS_ERROR_NAME_TO_SHORT

	; sprawdź czy podano jakiekolwiek znaki
	cmp	rcx,	VARIABLE_EMPTY
	je	.end	; nie

	; kod błędu, plik istnieje
	mov	rbx,	VARIABLE_VFS_ERROR_FILE_EXISTS

	; sprawdź czy istnieje plik o podanej nazwie w katalogu głównym
	call	cyjon_vfs_file_find
	jnc	.end	; plik istnieje, brak możliwości nadpisania z tego poziomu

	; kod błędu, brak miejsca na zapis pliku
	mov	rbx,	VARIABLE_VFS_ERROR_NO_FREE_SPACE

	; szukaj wolnego rekordu w katalogu głównym
	call	cyjon_vfs_knot_find_free
	jc	.end

	; zachowaj wskaźnik początku rekordu supła
	mov	r8,	rdi

	; aktualizuj rekord supła
	mov	rax,	qword [rsp + VARIABLE_QWORD_SIZE * 0x06]
	mov	qword [r8 + STRUCTURE_VFS_KNOT.permission],	rax	; uprawnienia do pliku
	mov	qword [r8 + STRUCTURE_VFS_KNOT.size],	rdx	; rozmiar pliku w Bajtach
	mov	qword [r8 + STRUCTURE_VFS_KNOT.chars],	rcx	; ilość znaków w nazwie pliku
	add	rdi,	STRUCTURE_VFS_KNOT.name
	rep	movsb	; nazwa pliku

	; przygotuj pierwszy blok danych pliku
	call	cyjon_page_allocate
	jc	.reverse	; brak miejsca w przestrzeni pamięci, cofnij przystkie naniesione zmiany

	; wyczyść blok danych
	call	cyjon_page_clear

	; zapisz do rekordu supła pierwszy blok danych pliku
	mov	qword [r8 + STRUCTURE_VFS_KNOT.id],	rdi

.continue:
	; ustaw wskaźnik adresu przechowywanego pliku w pamięci
	mov	rsi,	qword [rsp + VARIABLE_QWORD_SIZE * 0x02]

	; załaduj numer pierwszego bloku danych pliku
	mov	rdi,	qword [r8]

.save:
	; zachowaj aktualny adres bloku danych pliku
	mov	r9,	rdi

	; sprawdź czy cały/pozostała_część pliku mieści się w jednym bloku
	cmp	rdx,	STRUCTURE_VFS_BLOCK.SIZE - VARIABLE_QWORD_SIZE
	jbe	.last_block

	; przenieś część pliku do bloku danych i zmniejsz ilość pozostałą
	mov	rcx,	STRUCTURE_VFS_BLOCK.SIZE - VARIABLE_QWORD_SIZE
	sub	rdx,	rcx

	; przenieś
	shr	rcx,	VARIABLE_DIVIDE_BY_8
	rep	movsq

	; sprawdź czy jest opisany następny blok do uzupełniania danymi pliku
	cmp	qword [rdi],	VARIABLE_EMPTY
	ja	.store

	; zaalokuj następny blok danych pod plik
	call	cyjon_page_allocate
	jc	.reverse

	; załaduj informacje do aktualnego bloku
	mov	qword [r9 + STRUCTURE_VFS_BLOCK.link],	rdi

.store:
	; przywróć aktualny adres bloku danych pliku
	mov	rdi,	r9

	; załaduj numer następnego bloku do modyfikacji
	mov	rdi,	qword [rdi + STRUCTURE_VFS_BLOCK.link]

	; sprawdź czy koniec danych pliku
	cmp	rdx,	VARIABLE_EMPTY
	jne	.save

	; zwróć identyfikator pliku w katalogu głównym w RCX
	mov	qword [rsp + VARIABLE_QWORD_SIZE * 0x05],	r8

	; brak kodu błędu
	xor	rbx,	rbx

	; flaga, sukces
	clc

	; koniec zapisu
	jmp	 .end

.last_block:
	; przenieś pozostałą część pliku i zmniejsz ilość pozostałą
	mov	rcx,	rdx
	sub	rdx,	rcx

.copy:
	; przenieś część pliku do bloku danych
	rep	movsb

	; kontynuuj zapis
	jmp	.store

.end:
	; zwróć kod błędu
	mov	qword [rsp + VARIABLE_QWORD_SIZE * 0x06],	rbx

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

.reverse:
	; pobierz adres pierwszego bloku danych
	mov	rdi,	qword [r8 + STRUCTURE_VFS_KNOT.id]
	cmp	rdi,	VARIABLE_EMPTY
	je	.reverse_no_data

.reverse_loop:
	; pobierz adres następnego bloku danych
	mov	rsi,	qword [rdi + STRUCTURE_VFS_BLOCK.link]

	; zwolnij aktualny blok danych
	call	cyjon_page_release

	; przetwarzaj kolejny blok danych
	mov	rdi,	rsi
	cmp	rdi,	VARIABLE_EMPTY
	jne	.reverse_loop

.reverse_no_data:
	; usuń całkowitą zawartość rekordu
	xor	al,	al
	mov	rcx,	STRUCTURE_VFS_KNOT.SIZE
	mov	rdi,	r8
	stosb	; wyczyść rekord

	; flaga, błąd
	stc

	; koniec
	jmp	.end

;===============================================================================
; procedura wyszukuje w katalogu głównym wolnego supła/węzła dla pliku
; IN:
;	brak
;
; OUT:
;	rdi - adres bezwzględny znalezionego wolnego supła
;
; pozostałe rejestry zachowane
cyjon_vfs_knot_find_free:
	; zachowaj oryginalne rejestry
	push	rcx

	; załaduj adres początku tablicy supłów
	mov	rdi,	qword [variable_vfs_superblock + STRUCTURE_VFS_SUPERBLOCK.root]

.prepare:
	; ilość rekordów na blok
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_VFS_KNOT.SIZE

.loop:
	; sprawdź czy komórka "id" w opisie supła jest PUSTA
	cmp	qword [rdi + STRUCTURE_VFS_KNOT.id],	VARIABLE_EMPTY
	je	.found

	; przesuń wskaźnik na następny supeł
	add	rdi,	STRUCTURE_VFS_KNOT.SIZE

	; kontynuuj z kolejnymi rekordami
	loop	.loop

	; skończyły się rekordy z danego bloku, pobierz adres następnego bloku danych katalogu głównego
	and	di,	VARIABLE_MEMORY_PAGE_ALIGN
	mov	rdi,	qword [rdi + STRUCTURE_VFS_BLOCK.link]
	cmp	rdi,	VARIABLE_EMPTY
	ja	.prepare	; przeszukaj następny blok

	; brak następnych bloków danych katalogu głównego
	mov	rcx,	rdi	; zapamiętaj wskaźnik do komórki następnego bloku danych

	; rozszerz katalog główny o następny blok
	call	cyjon_page_allocate
	jc	.error	; brak miejsca w przstrzeni pamięci

	; wyczyść nowy blok danych katalogu głównego
	call	cyjon_page_clear

	; dołącz nowy blok danych
	mov	qword [rcx],	rdi

.found:
	; flaga, sukces
	clc

.end:
	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

.error:
	; flaga, błąd
	stc

	; koniec
	jmp	.end
;===============================================================================
; procedura ładuje zawartość pliku do pamięci
; IN:
;	rsi - numer pierwszego bloku danych pliku
;	rdi - adres gdzie załadować plik
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_vfs_file_read:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

.prepare:
	; rozmiar bloku do skopiowania
	mov	rcx,	STRUCTURE_VFS_BLOCK.SIZE - VARIABLE_QWORD_SIZE
	shr	rcx,	VARIABLE_DIVIDE_BY_8

	; kopiuj do procesu
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
; procedura przeszukuje katalog główny witualnego systemu plików za wskazaną nazwą pliku
; IN:
;	rcx - ilość znaków w nazwie pliku
;	rsi - ciąg znaków reprezentujący nazwę pliku
;
; OUT:
;	rdi - adres rekordu opisującego plik
;
; wszystkie rejestry zachowane
cyjon_vfs_file_find:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi
	push	rcx

	; zapamiętaj ilość znaków w nazwie pliku
	mov	rax,	rcx

	; wyzeruj numer rekordu

	; załaduj adres początku tablicy supłów
	mov	rdi,	qword [variable_vfs_superblock + STRUCTURE_VFS_SUPERBLOCK.root]

.prepare:
	; ilość supłów na blok
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_VFS_KNOT.SIZE

.loop:
	; sprawdź czy ilość znaków na nazwe pliku jest różna poszukiwanej
	cmp	qword [rdi + STRUCTURE_VFS_KNOT.chars],	rax
	jne	.continue

	; przesuń wskaźnik na ciąg znaków nazwy pliku
	add	rdi,	STRUCTURE_VFS_KNOT.name

	; ustaw ilość znaków w nazwie pliku
	xchg	rcx,	rax

	; porównaj ciągi
	call	library_compare_string

	; przywróć licznik
	xchg	rcx,	rax

	; znaleziono plik?
	jnc	.found

	; koryguj wskaźnik na początek rekordu
	sub	rdi,	STRUCTURE_VFS_KNOT.name

.continue:
	; przesuń wskaźnik na następny rekord
	add	rdi,	STRUCTURE_VFS_KNOT.SIZE

	; przeszukaj kolejne supły
	loop	.loop

	; skończyły się rekordy z danego bloku, pobierz adres następnego bloku danych katalogu głównego
	and	di,	VARIABLE_MEMORY_PAGE_ALIGN
	mov	rdi,	qword [rdi + STRUCTURE_VFS_BLOCK.link]
	cmp	rdi,	VARIABLE_EMPTY
	ja	.prepare	; przeszukaj następny blok

	; brak szukanego pliku/supła

	; flaga, błąd
	stc

	; koniec obsługi procedury
	jmp	.end
	
.found:
	; zwróć adres rekordu opisującego znleziony plik
	sub	rdi,	STRUCTURE_VFS_KNOT.name

	; flaga, sukces
	clc

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rsi
	pop	rax

	; powrót z procedury
	ret
