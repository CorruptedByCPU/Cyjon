;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_VFS_FILE_FLAGS_reserved				equ	00000001b

KERNEL_VFS_ERROR_FILE_exists				equ	0x01
KERNEL_VFS_ERROR_FILE_full				equ	0x02
KERNEL_VFS_ERROR_FILE_name_long				equ	0x04
KERNEL_VFS_ERROR_FILE_name_short			equ	0x05
KERNEL_VFS_ERROR_FILE_low_memory			equ	0x06
KERNEL_VFS_ERROR_FILE_overflow				equ	0x07	; np. niedozwolony znak przesyłany do urządzenia znakowego

struc	KERNEL_VFS_STRUCTURE_META_CHARACTER_DEVICE
	.width						resb	8
	.height						resb	8
	.start						resb	8
	.end						resb	8
	.SIZE:
endstruc

struc	KERNEL_VFS_STRUCTURE_META_BLOCK_DEVICE
	.entry						resb	8
	.properties					resb	1
	.reserved					resb	7
	.SIZE:
endstruc

struc	KERNEL_VFS_STRUCTURE_META_VOLUME
	.lba						resb	8	; numer pierwszego bloku danych rozpoczynający wolumen
	.length						resb	8	; rozmiar wolumenu w blokach danych nośnika
	.SIZE:
endstruc

kernel_vfs_semaphore					db	STATIC_FALSE

; wyrównaj pozycję supła do pełnego adresu
align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING
kernel_vfs_magicknot:					dq	STATIC_EMPTY	; data
							dq	STATIC_EMPTY	; size
							db	KERNEL_VFS_FILE_TYPE_directory
							dw	STATIC_EMPTY	; flags
							dq	STATIC_EMPTY	; time_modified
							db	0x01		; length
							db	"/"		; name

kernel_vfs_string_directory_local_or_overriding		db	".", "."

;===============================================================================
; wejście:
;	rsi - wskaźnik do meta danych
kernel_vfs_metadata_update:
	; powrót z procedury
	ret

	macro_debug	"kernel_vfs_metadata_update"

;===============================================================================
; wejście:
;	rsi - wskaźnik do supła katalogu nadrzędnego
;	rdi - wskaźnik do supła katalogu przetwarzanego
kernel_vfs_dir_symlinks:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	;-----------------------------------------------------------------------
	; utwórz dowiązanie symboliczne do siebie samego "."
	mov	ecx,	0x01	; ilość znaków w nazwie pliku
	mov	dl,	KERNEL_VFS_FILE_TYPE_symbolic_link
	mov	rsi,	kernel_vfs_string_directory_local_or_overriding
	call	kernel_vfs_file_touch

	; wskaźnik docelowy dowiązania symbolicznego
	mov	rax,	qword [rsp]
	mov	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data],	rax

	; następne dowiązanie dotyczy samego siebie? /
	cmp	qword [rsp + STATIC_QWORD_SIZE_byte],	rax
	je	.end	; tak, brak dowiązania symbolicznego do katalogu nadrzędnego :)

	;-----------------------------------------------------------------------
	; utwórz dowiązanie symboliczne do katalogu nadrzędnego ".."
	mov	ecx,	0x02	; ilość znaków w nazwie pliku
	mov	rdi,	rax	; utwórz w katalogu przetwarzanym
	call	kernel_vfs_file_touch

	; wskaźnik docelowy dowiązania symbolicznego
	mov	rax,	qword [rsp + STATIC_QWORD_SIZE_byte]
	mov	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data],	rax

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_vfs_dir_symlinks"

;===============================================================================
; wejście:
;	rcx - rozmiar ścieżki w znakach
;	rsi - wskaźnik do ścieżki
; wyjście:
;	Flaga CF - jeśli błąd
;	rax - kod błędu
;	rcx - ilość znaków w ostatnim pliku ścieżki
;	rsi - wskaźnik do ostatniego pliku w ścieżce
;	rdi - identyfikator ostatniego katalogu w ścieżce
kernel_vfs_path_resolve:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rsi
	push	rcx

	; utwórz zmienne lokalną
	push	STATIC_EMPTY

	; rozmiar przetworzonego ciągu
	xor	ebx,	ebx

	; ścieżka pusta?
	test	rcx,	rcx
	jz	.empty	; tak

	; domyślnie rozpocznij od katalogu głównego
	mov	rdi,	kernel_vfs_magicknot

	; ścieżka rozpoczyna się od znaku "/"?
	cmp	byte [rsi],	STATIC_SCANCODE_SLASH
	je	.prefix	; tak

	; ustaw wskaźnik na zadanie procesora logicznego
	call	kernel_task_active

	; pobierz identyfikator/węzeł katalogu roboczego rodzica
	mov	rdi,	qword [rdi + KERNEL_TASK_STRUCTURE.knot]

	; kontynuuj
	jmp	.suffix

.prefix:
	; usuń znak "/" z początku ścieżki
	dec	rcx
	inc	rsi

	; koniec ścieżki?
	test	rcx,	rcx
	jz	.root	; tak

	; początek ścieżki ponownie posiada znak "/"
	cmp	byte [rsi],	STATIC_SCANCODE_SLASH
	je	.prefix	; tak

.suffix:
	; ścieżka zakończona na znaku "/"?
	cmp	byte [rsi + rcx - 0x01],	STATIC_SCANCODE_SLASH
	jne	.cut	; nie

	; skróć ścieżkę o znak "/"
	dec	rcx

	; koniec ścieżki?
	test	rcx,	rcx
	jnz	.suffix	; nie

.cut:
	; szukaj znaku "/" od końca ścieżki
	cmp	byte [rsi + rcx - STATIC_BYTE_SIZE_byte],	STATIC_SCANCODE_SLASH
	je	.loop

	; skróć ścieżkę o ostatni plik
	inc	rbx
	dec	rcx

	; koniec ścieżki?
	test	rcx,	rcx
	jnz	.cut

	; ścieżka zawiera tylko "plik"

	; kontynuuj
	jmp	.ready

.doubled:
	; znaleziono "/" lub "//" w ścieżce, pomiń
	dec	rcx
	inc	rsi

.loop:
	; ścieżka przetworzona?
	test	rcx,	rcx
	jz	.ready	; tak

	; zachowaj rozmiar ścieżki
	mov	qword [rsp],	rcx

	; pobierz nazwę katalogu
	mov	al,	STATIC_SCANCODE_SLASH	; separator plików w ścieżce
	macro_library	LIBRARY_STRUCTURE_ENTRY.string_cut
	jc	.ready	; przetworzono ścieżkę

	; zwrócono pusty ciąg?
	test	rcx,	rcx
	jz	.leave	; tak

	; kod błędu, pliku nie znaleziono
	mov	eax,	KERNEL_ERROR_vfs_file_not_found

	; plik istnieje?
	call	kernel_vfs_file_find
	jc	.error	; nie

	; plik jest dowiązaniem symbolicznym?
	test	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_symbolic_link
	jz	.no_link	; nie

	; przeładuj wskaźnik
	mov	rdi,	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

.no_link:
	; kod błędu, to nie jest katalog
	mov	eax,	KERNEL_ERROR_vfs_file_not_directory

	; plik jest katalogiem?
	test	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_directory
	jz	.error	; nie

	; koryguj ścieżkę
	sub	qword [rsp],	rcx
	add	rsi,	rcx

.leave:
	; przywróć rozmiar pozostałej ścieżki
	mov	rcx,	qword [rsp]

	; przetwarzaj dalej
	jmp	.doubled

.ready:
	; koryguj informacje o ilości znaków pozostałych w ścieżce
	mov	rcx,	rbx

.prepared:
	; zwróć
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rcx
	mov	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02],	rsi

	; flaga, sukces
	clc

	; koniec
	jmp	.end

.root:
	; ustaw wskaźnik na plik katalogu bierzącego
	mov	rcx,	0x01
	mov	rsi,	kernel_vfs_string_directory_local_or_overriding

	; kontynuuj
	jmp	.prepared

.empty:
	; kod błędu, błąd ścieżki
	mov	eax,	KERNEL_ERROR_vfs_file_not_found

.error:
	; zwróć kod błędu
	mov	qword [rsp + STATIC_QWORD_SIZE_byte * 0x05],	rax

	; flaga, błąd
	stc

.end:
	; zwolnij zmienną lokalną
	add	rsp,	STATIC_QWORD_SIZE_byte

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rsi
	pop	rdx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_vfs_path_resolve"

;===============================================================================
; wejście:
;	rcx - ilość znaków w nazwie pliku
;	bx - uprawnienia
;	dl - typ pliku
;	rsi - wskaźnik do nazwy pliku
;	rdi - supeł/identyfikator katalogu w którym utworzyć nowy plik
; wyjście:
;	Flaga CF, jeśli błąd
;	rdi - supeł/identyfikator utworzonego pliku
kernel_vfs_file_touch:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi
	push	rax

	; kod błędu: nazwa pliku za długa
	mov	eax,	KERNEL_VFS_ERROR_FILE_name_long

	; sprawdź obsługiwaną długość nazwy pliku
	cmp	rcx,	KERNEL_VFS_STRUCTURE_KNOT.SIZE - KERNEL_VFS_STRUCTURE_KNOT.name
	ja	.error

	; kod błędu: nazwa pliku za krótka
	mov	eax,	KERNEL_VFS_ERROR_FILE_name_short

	; sprawdź czy podano jakąkolwiek nazwę
	cmp	rcx,	STATIC_EMPTY
	je	.error

	; kod błędu: plik istnieje
	mov	eax,	KERNEL_VFS_ERROR_FILE_exists

	; sprawdź czy istnieje plik o podanej nazwie
	call	kernel_vfs_file_find
	jnc	.error	; istnieje plik o podanej nazwie

	; kod błędu: brak miejsca
	mov	rax,	KERNEL_VFS_ERROR_FILE_full

	; szukaj wolnego rekordu w katalogu głównym
	call	kernel_vfs_knot_prepare
	jc	.end	; brak wolnego rekordu

	; aktualizuj wpis supła

	; plik typu katalog?
	cmp	dl,	KERNEL_VFS_FILE_TYPE_directory
	jne	.no_directory	; nie

	; zachowaj wskaźnik supła
	mov	rax,	rdi

	; przygotuj blok danych dla nowego klatalogu
	call	kernel_memory_alloc_page
	jnc	.assigned	; przydzielono

	; zwolnij wpis w katalogu
	mov	word [rdi + KERNEL_VFS_STRUCTURE_KNOT.flags],	STATIC_EMPTY

	; koniec obsługi
	jmp	.error

.assigned:
	; wyczyść blok danych katalogu
	call	kernel_page_drain
	mov	qword [rax + KERNEL_VFS_STRUCTURE_KNOT.data],	rdi

	; przywróć wskaźnik supła
	mov	rdi,	rax

	; zachowaj wskaźnik do nazwy katalogu
	push	rsi

	; utwórz podstawowe dowiązania symboliczne
	mov	rsi,	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02]	; wskaźnik supła katalogu nadrzędnego
	call	kernel_vfs_dir_symlinks

	; przywróć wskaźnik do nazwy katalogu
	pop	rsi

.no_directory:
	; uprawnienia pliku
	mov	word [rdi + KERNEL_VFS_STRUCTURE_KNOT.mode],	bx

	; ilość znaków w nazwie pliku
	mov	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.length],	cl

	; zachowaj typ pliku
	mov	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type],	dl

	; zachowaj wskaźnik supła
	push	rdi

	; nazwa pliku
	add	rdi,	KERNEL_VFS_STRUCTURE_KNOT.name
	rep	movsb

	; przywróć wskaźnik supła
	pop	rdi
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rdi	; zwróć

	; koniec procedury
	jmp	.end

.error:
	; zwróć kod błędu
	mov	qword [rsp],	rax

	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rax
	pop	rdi
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_vfs_file_touch"

;===============================================================================
; weście:
;	rcx - ilość znaków w nazwie pliku
;	rsi - wskaźnik do nazwy plik
;	rdi - supeł/identyfikator katalogu przeszukiwanego
; wyjście
;	Flaga CF - jeśli błąd
;	rax - kod błędu
;	rdi - wskaźnik supła opisującego plik
kernel_vfs_file_find:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; zapamiętaj ilość znaków w nazwie pliku
	mov	rax,	rcx

	; ustaw wskaźnik na pierwszy blok danych katalogu
	mov	rdi,	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

.prepare:
	; ilość supłów na blok
	mov	rcx,	STATIC_STRUCTURE_BLOCK.link / KERNEL_VFS_STRUCTURE_KNOT.SIZE

.loop:
	; ilość znaków w nazwie się zgadza?
	cmp	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.length],	al
	jne	.next	; nie

	; przesuń wskaźnik na ciąg znaków nazwy pliku
	add	rdi,	KERNEL_VFS_STRUCTURE_KNOT.name

	; ustaw ilość znaków w nazwie pliku
	xchg	rcx,	rax

	; porównaj nazwy plików
	macro_library	LIBRARY_STRUCTURE_ENTRY.string_compare

	; przywróć licznik
	xchg	rcx,	rax

	; znaleziono plik?
	jnc	.found

	; cofnij wskaźnik na początek supła
	sub	rdi,	KERNEL_VFS_STRUCTURE_KNOT.name

.next:
	; przesuń wskaźnik na następny supeł
	add	rdi,	KERNEL_VFS_STRUCTURE_KNOT.SIZE

	; sprawdź kolejne supły
	dec	rcx
	jnz	.loop

	; skończyły się rekordy z danego bloku, pobierz adres następnego bloku danych katalogu głównego
	and	di,	STATIC_PAGE_mask
	mov	rdi,	qword [rdi + STATIC_STRUCTURE_BLOCK.link]
	test	rdi,	rdi	; koniec bloków danych?
	jnz	.prepare	; przeszukaj następny blok danych katalogu

	; brak poszukiwanego pliku, zwróć kod błędu
	mov	qword [rsp + STATIC_QWORD_SIZE_byte * 0x03],	KERNEL_ERROR_vfs_file_not_found

	; flaga, błąd
	stc

	; koniec obsługi procedury
	jmp	.end

.found:
	; cofnij wskaźnik na wpis
	sub	rdi,	KERNEL_VFS_STRUCTURE_KNOT.name

.unload:
	; plik jest dowiązaniem symbolicznym?
	test	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_symbolic_link
	jz	.return	; nie

	; załaduj adres supła wskazywanego przez dowiązanie symboliczne
	mov	rdi,	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

	; sprawdź raz jeszcze
	jmp	.unload

.return:
	; zwróć adres supła opisującego znleziony plik
	mov	qword [rsp],	rdi

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_vfs_file_find"

;===============================================================================
; wejście:
;	dl - typ pliku
;	rdi - supeł/identyfikator katalogu
; wyjście:
;	Flaga CF, jeśli nie znaleziono wolnego miejsca
kernel_vfs_knot_prepare:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; zablokuj dostęp do systemu plików
	macro_lock	kernel_vfs_semaphore, 0

	; ustaw wskaźnik na pierwszy blok danych katalogu
	mov	rdi,	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

.prepare:
	; ilość supłów na blok
	mov	ecx,	STATIC_STRUCTURE_BLOCK.link / KERNEL_VFS_STRUCTURE_KNOT.SIZE

.loop:
	; wolny supeł?
	cmp	word [rdi + KERNEL_VFS_STRUCTURE_KNOT.flags],	STATIC_EMPTY
	je	.ready	; tak

	; przesuń wskaźnik na następny supeł
	add	rdi,	KERNEL_VFS_STRUCTURE_KNOT.SIZE

	; kontynuuj z kolejnymi rekordami
	loop	.loop

	; skończyły się rekordy z danego bloku, pobierz adres następnego bloku danych katalogu głównego
	and	di,	STATIC_PAGE_mask
	mov	rdi,	qword [rdi + STATIC_STRUCTURE_BLOCK.link]
	test	rdi,	rdi	; koniec bloków danych?
	jnz	.prepare	; przeszukaj następny blok danych katalogu

	; brak wolnych supłów w aktualnym bloku danych katalogu
	mov	rcx,	rdi	; zapamiętaj wskaźnik połączenia następnego bloku danych

	; przygotuj miejsce do kolejny blok danych katalogu
	call	kernel_memory_alloc_page
	jnc	.ok	; brak miejsca w przstrzeni pamięci

	; błąd, brak miejsca
	stc

	; koniec procedury
	jmp	.end

.ok:
	; wyczyść nowy blok danych katalogu głównego
	call	kernel_page_drain

	; dołącz nowy blok danych do katalogu głównego
	mov	qword [rcx],	rdi

.ready:
	; zablokuj dostęp do supła
	mov	word [rdi + KERNEL_VFS_STRUCTURE_KNOT.flags],	KERNEL_VFS_FILE_FLAGS_reserved

	; zwiększ licznik supłów w katalogu bierzącym
	mov	rcx,	qword [rsp]
	inc	qword [rcx + KERNEL_VFS_STRUCTURE_KNOT.size]

	; zwróć wskaźnik do supła
	mov	qword [rsp],	rdi

.end:
	; zwolnij dostęp do systemu plików
	mov	byte [kernel_vfs_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_vfs_knot_prepare"

;===============================================================================
; wejście:
;	rcx - ilość danych w Bajtach
;	rsi - wskaźnik do danych pliku
;	rdi - supeł/identyfikator pliku do nadpisania
; wyjście:
;	Flaga CF, jeśli błąd
kernel_vfs_file_write:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rcx
	push	rdi

	; zachowaj identyfikator/wskaźnik do supła pliku
	mov	rbx,	rdi

	; plik zawiera jakikolwiek blok danych?
	cmp	qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data],	STATIC_EMPTY
	jne	.exist	; tak

	; przygotuj przestrzeń pod blok danych
	call	kernel_memory_alloc_page
	jc	.end	; brak wolnego miejsca w przestrzeni pamięci

	; wyczyść blok danych pliku
	call	kernel_page_drain

	; podłącz blok danych do pliku
	mov	qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data],	rdi

.exist:
	; zapisz do pliku N pierwszych danych bloku
	mov	rdx,	qword [rsp + STATIC_QWORD_SIZE_byte]

	; pobierz pierwszy blok danych pliku
	mov	rdi,	qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data]

	; wszystkie dane zmieszczą się w pierwszym bloku danych?
	cmp	rcx,	STATIC_STRUCTURE_BLOCK.link
	jbe	.all_in_one	; tak

	; oblicz ilość bloków danych niezbędnych do zapisania danych
	mov	rax,	STATIC_STRUCTURE_BLOCK.link
	xchg	rax,	rcx
	xor	edx,	edx	; usuń starszą część rozmiaru
	div	rcx

	; reszta z dzielenia?
	test	dx,	dx
	jz	.no_modulo	; nie

	; ilość dodatkowych bloków +1
	mov	ecx,	STATIC_TRUE

.no_modulo:
	; zarezerwuj niezbędą ilość bloków dla pliku
	add	rcx,	rax
	call	kernel_page_secure
	jc	.end	; brak wystarczającej ilości pamięci

	; wykorzystuj zarezerwowane bloki jeśli wystąpi potrzeba
	mov	rbp,	rcx

	; zapisz do pliku N pierwszych danych bloku
	mov	rdx,	qword [rsp + STATIC_QWORD_SIZE_byte]

.loop:
	; rozmiar bloku danych w Bajtach
	mov	ecx,	STATIC_STRUCTURE_BLOCK.link
	shr	ecx,	STATIC_DIVIDE_BY_8_shift
	rep	movsq

	; zapisano pierwszą partię danych do pliku
	sub	rdx,	STATIC_STRUCTURE_BLOCK.link

	; następny blok danych istnieje?
	cmp	qword [rdi],	STATIC_EMPTY
	jne	.next_block	; tak

.next_block:
	; pobierz następny blok danych pliku
	mov	rdi,	qword [rdi]

	; pozostałe dane pliku mieszczą się w jednym bloku?
	cmp	rdx,	STATIC_STRUCTURE_BLOCK.link
	ja	.loop	; nie

.all_in_one:
	; pozostały dane do zapisania
	test	rdx,	rdx
	jz	.saved	; nie

	; zapisz końcówkę danych do bloku
	mov	rcx,	rdx
	rep	movsb

	; zwolnij pozostałe bloki danych pliku
	and	di,	STATIC_PAGE_mask
	mov	rdi,	qword [rdi + STATIC_STRUCTURE_BLOCK.link]

.remove:
	; koniec bloków danych?
	test	rdi,	rdi
	jz	.saved	; tak

	; zachowaj następny prawdopodobny blok danych
	push	qword [rdi + STATIC_STRUCTURE_BLOCK.link]

	; zwolnij blok danych
	call	kernel_memory_release_page

	; przywróć następny prawdopodobny blok danych
	pop	rdi

	; kontynuuj
	jmp	.remove

.saved:
	; zwolnij pozostałą ilość zarezerwowanych bloków
	sub	qword [kernel_page_reserved_count],	rbp
	add	qword [kernel_page_free_count],	rbp

	; aktualizuj informacje o nowym rozmiarze pliku
	mov	rcx,	qword [rsp + STATIC_QWORD_SIZE_byte]
	mov	qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.size],	rcx

	; aktualizuj informacje o czasie modyfikacji pliku
	mov	rcx,	qword [driver_rtc_microtime]
	mov	qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.time_modified],	rcx

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rdx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_vfs_file_write"

;===============================================================================
; wejście:
;	rcx - ilość danych w Bajtach
;	rsi - wskaźnik do danych pliku
;	rdi - supeł/identyfikator pliku do modyfikacji
; wyjście:
;	Flaga CF, jeśli błąd
;	eax - kod błędu
kernel_vfs_file_append:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	; zmienna lokalna
	push	rcx

	; zachowaj identyfikator/wskaźnik do supła pliku
	mov	rbx,	rdi

	; plik zawiera jakikolwiek blok danych?
	cmp	qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data],	STATIC_EMPTY
	jne	.exist	; tak

	; kod błędu, brak wolnego miejsca
	mov	eax,	KERNEL_VFS_ERROR_FILE_low_memory

	; przygotuj przestrzeń pod blok danych
	call	kernel_memory_alloc_page
	jc	.end	; brak wolnego miejsca w przestrzeni pamięci

	; wyczyść blok danych pliku
	call	kernel_page_drain

	; podłącz blok danych do pliku
	mov	qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data],	rdi

.exist:
	; pobierz ostatni blok danych pliku
	mov	rdi,	qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data]

.last_one:
	; jest to ostatni blok danych pliku?
	cmp	qword [rdi + STATIC_STRUCTURE_BLOCK.link],	STATIC_EMPTY
	je	.found	; tak

	; pobierz następny blok danych pliku
	mov	rdi,	qword [rdi + STATIC_STRUCTURE_BLOCK.link]

	; kontynuuj przeszukiwanie
	jmp	.last_one

.found:
	; oblicz ilość danych przechowywanych w ostatnim bloku danych pliku
	mov	rax,	qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.size]
	mov	rcx,	STATIC_STRUCTURE_BLOCK.link
	xor	edx,	edx
	div	rcx

	; przesuń wskaźnik w ostatnim bloku na koniec danych
	add	rdi,	rax

	; przelicz na ilość wolnego miejsca w ostatnim bloku danych pliku
	sub	rax,	STATIC_STRUCTURE_BLOCK.link
	not	rax
	inc	rax

	; ustaw licznik na miejsce
	mov	rcx,	rax

	; zmieścimy całość danych do ostatniego bloku danych pliku?
	cmp	rcx,	qword [rsp]
	jbe	.more	; nie

.less:
	; pobierz pozostałą ilość danych do przetworzenia
	xor	ecx,	ecx

	; wyzeruj ilość danych do przetworzenia
	xchg	rcx,	qword [rsp]

	; kontynuuj
	jmp	.write

.more:
	; zmiejsz ilość danych do przetworzenia
	sub	qword [rsp],	rcx

.write:
	; kopiuj dane do bloku danych pliku
	rep	movsb

	; koniec danych pliku?
	cmp	qword [rsp],	STATIC_EMPTY
	je	.ready	; tak

	; zachowaj wskaźnik końca aktualnego bloku danych
	mov	rdx,	rdi

	; kod błędu, brak wolnego miejsca
	mov	eax,	KERNEL_VFS_ERROR_FILE_low_memory

	; przygotuj przestrzeń pod blok danych
	call	kernel_memory_alloc_page
	jc	.end	; brak wolnego miejsca w przestrzeni pamięci

	; wyczyść blok danych pliku
	call	kernel_page_drain

	; dołącz nowy blok danych do pliku
	mov	qword [rdx],	rdi

	; ilość wolnego miejsca w nowym bloku danych
	mov	ecx,	STATIC_STRUCTURE_BLOCK.link

	; zmieścimy wszystko do aktualnego bloku danych?
	cmp	qword [rsp],	rcx
	jbe	.less	; tak
	ja	.more	; nie

.ready:
	; aktualizuj informacje o rozmiarze pliku
	mov	rcx,	qword [rsp + STATIC_QWORD_SIZE_byte * 0x03]
	add	qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.size],	rcx

	; aktualizuj informacje o czasie modyfikacji pliku
	mov	rcx,	qword [driver_rtc_microtime]
	mov	qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.time_modified],	rcx

.end:
	; zwolnij zmienną lokalną
	add	rsp,	STATIC_QWORD_SIZE_byte

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_vfs_file_append"

;===============================================================================
; wejście:
;	rsi - wskaźnik bezpośredni do supła pliku
;	rdi - adres docelowy danych pliku
; wyjście:
;	Flaga CF - jeśli błąd
;	rcx - rozmiar załadowanych danych
kernel_vfs_file_read:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rsi
	push	rdi

.symbolic_link:
	; plik jest dowiązaniem symbolicznym?
	test	word [rsi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_symbolic_link
	jz	.file	; nie

	; pobierz prawidłowy supeł pliku
	mov	rsi,	qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.data]

	; sprawdź raz jeszcze
	jmp	.symbolic_link

.file:
	; rozmiar pliku w Bajtach
	mov	rax,	qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.size]

	; plik jest katalogiem?
	test	byte [rsi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_directory
	jz	.regular_file	; nie

	; ilość wykorzystanej przestrzeni dla bloków danych w Bajtach
	xor	eax,	eax

	; pobierz wskaźnik pierwszego bloku danych
	mov	rcx,	qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.data]

.block:
	; zwiększ rozmiar katalogu w Bajtach
	add	rax,	STATIC_STRUCTURE_BLOCK.link

	; pobierz wskaźnik następnego bloku danych
	mov	rcx,	qword [rcx + STATIC_STRUCTURE_BLOCK.link]

	; koniec bloków danych?
	test	rcx,	rcx
	jnz	.block	; nie

.regular_file:
	; zachowaj rozmiar wczytanych danych
	push	rax

	; pobierz pierwszy blok danych pliku
	mov	rsi,	qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.data]

.loop:
	; domyślny rozmiar bloku odczytanych
	mov	rcx,	STATIC_STRUCTURE_BLOCK.link

	; następna część pliku mieści się w pojedyńczym bloku danych?
	cmp	rax,	rcx
	ja	.next_block	; nie

	; tak
	mov	rcx,	rax

.next_block:
	; pozostała ilość danych do załadowania
	sub	rax,	rcx

	; kopiuj do przestrzeni procesu
	rep	movsb

	; pobierz następny blok danych pliku
	and	si,	STATIC_PAGE_mask
	mov	rsi,	qword [rsi + STATIC_STRUCTURE_BLOCK.link]

	; koniec danych pliku?
	test	rax,	rax
	jnz	.loop	; nie

	; zwróć rozmiar wczytanych danych
	pop	rcx

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_vfs_file_read"
