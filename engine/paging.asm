;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; zablokuj dostęp do modyfikacji pamięci
variable_page_semaphore						db	VARIABLE_FALSE
; zablokuj dostęp do Binarnej Mapy Pamięci
variable_page_allocate_semaphore				db	VARIABLE_FALSE

; adres tablicy stronicowania PML4 jądra systemu
variable_page_pml4_address					dq	VARIABLE_EMPTY

; 64 Bitowy kod programu
[BITS 64]

;=======================================================================
; procedura wyszukuje i rezerwuje przestrzeń o podanym rozmiarze (ilość stron) w przestrzeni fizycznej
; MAX: 256 KiB (64 strony)
;
; IN:
;	rcx	- ilość stron do zarezerwowania
; OUT:
;	rdi	- adres przestrzeni zarezerwowanej o podanym rozmiarze
;		  lub ZERO jeśli brak dostępnej przestrzeni o podanym rozmiarze
;
; pozostałe rejestry zachowane
cyjon_page_find_free_memory_physical:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	pushfq

	; czy my wiemy wogóle co robimy?
	cmp	rcx,	VARIABLE_EMPTY
	je	.no_memory

	; szukaj przestrzeni od początku binarnej mapy pamięci
	mov	rsi,	qword [variable_binary_memory_map_address_start]

	; zablokuj dostęp do rezerwacji stron
	mov	byte [variable_page_semaphore],	VARIABLE_TRUE

	; sprawdź czy istnieje możliwość zarezerowania podanej przestrzeni (jeśli nie jest pofragmentowana)
	cmp	qword [variable_binary_memory_map_free],	rcx
	jb	.no_memory

.restart:
	; koniec przeszukiwanej tablicy?
	cmp	rsi, qword [variable_binary_memory_map_address_end]
	je	.no_memory

	; zachowaj licznik
	push	rcx

	; zresetuj licznik ciągłości odnalezionych stron
	xor	rdx,	rdx

	; ostatni bit rejestru 64 bitowego
	mov	rcx,	63

	; pobierz zawartość pakietu
	lodsq

.loop:
	; sprawdź czy strona jest wolna
	bt	rax,	rcx
	jnc	.stop

	; znaleziono stronę
	inc	rdx

	; znaleziono odpowiednią ilość?
	cmp	rdx,	qword [rsp]
	je	.found

.continue:
	; szukaj dalej
	loop	.loop

	; przywróć licznik
	pop	rcx
	; i zacznij szukać w nastepnym rekordzie
	jmp	.restart

.stop:
	; nie znaleziono ciągłości stron
	xor	rdx,	rdx

	; szukaj dalej
	jmp	.continue

.found:
	; zarezerwuj miejsce
	btr	rax,	rcx

	; przesuń wskaźnik na poprzedni bit
	inc	rcx

	; zarezerwuj pozostałe strony
	dec	rdx
	jnz	.found

	; koryguj wskaźnik pierwszego bitu przestrzeni
	dec	rcx

	; usuń zmienną lokalną z stosu
	add	rsp,	0x08

	; skoryguj adres wskaźnika źródłowego, przesuwając go na adres przetwarzanego pakietu
	sub	rsi,	0x08

	; oraz aktualizujemy binarną mapę o zmodyfikowany pakiet
	mov	qword [rsi],	rax

	; wyliczamy przesunięcie wewnątrz binarnej mapy
	sub	rsi,	qword [variable_binary_memory_map_address_start]
	; zamieniamy przesunięcie z Bajtów na bity
	shl	rsi,	3	; *8

	; tworzymy lustrzane odbicie numeru znalezionego bitu, aby prawidłowo przedstawić numer strony wewnątrz "pakietu"
	mov	rdi,	63
	sub	rdi,	rcx

	; zwróć sumę wyników
	add	rdi,	rsi

	; zamień całkowity numer bitu na względny adres strony
	shl	rdi,	VARIABLE_MULTIPLE_BY_4096

	; w binarnej mapie pamięci opisaliśmy przestrzeń zaczynającą się od adresu fizycznego 0x0000000000100000
	; zamień adres fizyczny względny na bezwzględny
	add	rdi,	VARIABLE_KERNEL_PHYSICAL_ADDRESS

	; zmniejsz ilość dostępnej pamięci
	mov	rax,	qword [rsp + ( VARIABLE_QWORD_SIZE * 0x03 )]
	sub	qword [variable_binary_memory_map_free],	rax

	; zwróć wynik
	jmp	.end

.no_memory:
	; zwróć brak przestrzeni wolnej
	xor	rdi,	rdi

.end:
	; odblokuj dostęp do rezerwacji stron
	mov	byte [variable_page_semaphore],	VARIABLE_FALSE

	; przywróć oryginalne rejestry
	popfq
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; procedura zwalnia zajętą przestrzeń fizyczną
; IN:
;	rcx - ilość stron do zwolnienia
;	rdi - początek przestrzeni do zwolnienia
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_page_release_physical_area:
	; zachowan oryginalne rejestry
	push	rcx
	push	rdi

.loop:
	; zwolnij kolejne strony
	call	cyjon_page_release

	; zwiększ ilość wolnej przestrzeni
	inc	qword [variable_binary_memory_map_free]

	; przesuń wskaźnik na następną stonę
	add	rdi,	VARIABLE_MEMORY_PAGE_SIZE

	; kontynuuj z pozostałymi
	loop	.loop

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
; procedura zwalnia WSZYSTKIE strony zajęte przez tablicę PMLx
; IN:
;	rbx - poziom tablicy PML rozpoczynający
;	rcx - ilość rekordów do zwolnienia z tablicy
;	rdi - wskaźnik do tablicy PML4 (+przesunięcie, jeśli potrzeba)
;	
; OUT:
;	brak
cyjon_page_release_area:
	; wejdź do następnego poziomu tablicy PML
	dec	rbx
	mov	rcx,	512	; ilość rekordów do zwolnienia w następnym poziomie tablicy PML

	; aktualna tablica PML1?
	cmp	rbx,	0x01
	je	.continue	; jeśli tak, kontynuuj

.loop:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; sprawdź czy rekord jest pusty
	cmp	qword [rdi],	VARIABLE_EMPTY
	je	.empty	; jeśli nie, kontynuuj

	; pobierz adres tablicy następnego poziomu tablicy PML
	mov	rdi,	qword [rdi]
	and	di,	0xFF00	; usuń flagi z adres następnej tablicy PML

	; zapamiętaj adres nowej tablicy PML
	push	rdi

	; rekurencja, do czasu wejścia do tablicy PML1
	call	cyjon_page_release_area

	; przywróć adres tablicy PML aktualnie przetwarzanego rekordu
	pop	rdi

	; zwolnij przestrzeń
	call	cyjon_page_release

	; zwolniono tablicę PML > 1
	cmp	rbx,	1
	je	.no_release_table

	; zmniejszono rozmiar stronicowania
	dec	qword [variable_binary_memory_map_paged]

.no_release_table:
	; wróć do poprzedniego poziomu tablicy PML
	inc	rbx

.empty:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; następny rekord aktualnej tablicy PML
	add	rdi,	0x08

	; przeszukaj kolejne rekordy
	loop	.loop

.end:
	; powrót z procedury
	ret

.continue:
	; sprawdź czy rekord jest pusty
	cmp	qword [rdi],	VARIABLE_EMPTY
	jne	.after	; jeśli nie, zwolnij przestrzeń opisywaną przez rekord

.next:
	add	rdi,	0x08	; następny rekord
	loop	.continue

	; powrót z procedury
	ret

.after:
	; zachowaj oryginalny rejestr
	push	rdi

	; pobierz adres przestrzeni do zwolnienia
	mov	rdi,	qword [rdi]
	and	di,	0xFF00	; usuń flagi

	; wyczyść i zwolnij przestrzeń
	call	cyjon_page_release

	;przywróć oryginalny rejestr
	pop	rdi

	; przetwórz następny rekord
	jmp	.next

;===============================================================================
; tworzy nowe tablice stronicowania opisując przestrzeń pamięci fizycznej względem utworzonej binarnej mapy pamięci
; IN:
;	brak
; OUT:
;	brak
recreate_paging:
	; utworzenie nowego stronicowania specjalnie dla jądra
	; będzie skutkowało utworzeniem nowego stosu/stosu kontekstu jądra
	; zapamiętajmy adres powrotu z procedury
	mov	rax,	qword [rsp]
	mov	qword [recreate_paging],	rax

	; przygotuj miejsce dla tablicy PML4 jądra
	; tak dla własnego dobra, stosuję numeracje dla tablic
	; PML4, PML3(PDP), PML2(PD), PML1(PT) - prostrze i wygodniejsze
	call	cyjon_page_allocate

	; zwiększono rozmiar stronicowania
	inc	qword [variable_binary_memory_map_paged]

	; wyczyść stronę
	call	cyjon_page_clear

	; zapamiętaj adres fizyczny/logiczny tablicy PML4 jądra
	mov	qword [variable_page_pml4_address],	rdi

	; opisz w tablicach stronicowania jądra przestrzeń zarejestrowaną w binarnej mapie pamięci
	mov	rax,	VARIABLE_KERNEL_PHYSICAL_ADDRESS
	; ustaw właściwości rekordów/stron w tablicach stronicowania
	mov	rbx,	VARIABLE_MEMORY_PAGE_FLAG_AVAILABLE + VARIABLE_MEMORY_PAGE_FLAG_WRITE	; flagi: 4 KiB, Administrator, Odczyt/Zapis, Dostępna
	; opisz w tablicach stronicowania jądra przestrzeń o rozmiarze N stron
	mov	rcx,	qword [variable_binary_memory_map_total]
	; załaduj adres fizyczny/logiczny tablicy PML4 jądra
	mov	r11,	rdi

	; mapuj opisaną przestrzeń fizyczną
	call	cyjon_page_map_physical_area

	; opisz w tablicach stronicowania jądra przestrzeń pamieci ekranu
	mov	rax,	qword [variable_screen_base_address]
	; ustaw właściwości rekordów/stron w tablicach stronicowania
	mov	rbx,	VARIABLE_MEMORY_PAGE_FLAG_AVAILABLE + VARIABLE_MEMORY_PAGE_FLAG_WRITE + VARIABLE_MEMORY_PAGE_FLAG_USER	; flagi: Użytkownik/Process, Odczyt/Zapis, Dostępna
	; załaduj adres fizyczny/logiczny tablicy PML4 jądra
	mov	r11,	rdi
	; opisz w tablicach stronicowania jądra przestrzeń o rozmiarze N stron
	mov	rdi,	qword [variable_screen_size]
	; wyrównaj do pełnej strony
	call	library_align_address_up_to_page
	; ustaw licznik
	mov	rcx,	rdi
	; zamień na ilość stron
	shr	rcx,	VARIABLE_DIVIDE_BY_4096

	; mapuj opisaną przestrzeń fizyczną
	call	cyjon_page_map_physical_area

	; utwórz stos/stos kontekstu dla jądra na końcu pierwszej połowy przestrzeni logicznej
	; przyjąłem, że jądro systemu otrzyma pierwszą połowę całej dostępnej przestrzeni pamięci logicznej
	; znaczne ułatwienie przy debugowaniu (bochs potrafi się sypać namiętnie)
	; tj. 0x0000000000000000 - 0x00007FFFFFFFFFFF
	; a pozostałe procesy/programy, drugą połowę
	; tj. 0xFFFF8000000000000000 - 0xFFFFFFFFFFFFFFFF
	mov	rax,	VARIABLE_KERNEL_STACK_ADDRESS	; ostatnia strona o rozmiarze 4 KiB
	mov	rcx,	1	; przeznacz jedną stronę na stos/stos kontekstu jądra systemu
	; mapuj opisaną przestrzeń fizyczną
	call	cyjon_page_map_logical_area

	; przeładuj stronicowanie
	mov	rax,	qword [variable_page_pml4_address]
	mov	cr3,	rax

	; stronicowanie utworzone, pora wrócić z procedury
	; ustawiamy wskaźnik szczytu stosu na koniec przestrzeni stosu
	mov	rsp,	VARIABLE_KERNEL_STACK_ADDRESS + 0x1000

	; i wychodzimy z procedury, imitacją RET
	jmp	qword [recreate_paging]

;=======================================================================
; pobiera adres fizyczny/logiczny wolnej strony do wykorzystania
; IN:
;	brak
; OUT:
;	rdi - adres wolnej strony, lub ZERO jeśli brak
;
; pozostałe rejestry zachowane
cyjon_page_allocate:
	; zachowaj oryginalne rejestry i flagi
	push	rax
	push	rcx
	push	rsi

.wait:
	; sprawdź czy binarna mapa pamięci jest dostępna do modyfikacji
	cmp	byte [variable_page_allocate_semaphore],	VARIABLE_TRUE
	je	.wait	; nie, czekaj na zwolnienie

	; zarezerwuj binarną mapę pamięci dla siebie
	mov	byte [variable_page_allocate_semaphore],	VARIABLE_TRUE

	; sprawdź czy istnieją dostępne strony
	cmp	qword [variable_binary_memory_map_free],	VARIABLE_EMPTY
	je	.end	; brak, zakończ procedurę

	; istnieją dostępne strony, zmniejsz ich ilość o jedną
	dec	qword [variable_binary_memory_map_free]

	; załaduj do wskaźnika źródłowego adres logiczny początku binarnej mapy pamięci
	mov	rsi,	qword [variable_binary_memory_map_address_start]
	; załaduj do wskaźnika docelowego adres logiczny końca binarnej mapy pamięci
	mov	rdi,	qword [variable_binary_memory_map_address_end]

	; przeszukaj binarną tablicę za dostępnym bitem
	call	library_find_free_bit

	; sprawdź kod błędu
	cmp	rax,	VARIABLE_FULL
	jne	.found

	; flaga, błąd
	stc

	; koniec
	jmp	.end

.found:
	; załaduj znaleziony bit
	mov	rdi,	rax

	; zamień całkowity numer bitu na względny adres strony
	shl	rdi,	VARIABLE_MULTIPLE_BY_4096

	; w binarnej mapie pamięci opisaliśmy przestrzeń zaczynającą się od adresu fizycznego 0x0000000000100000
	; zamień adres fizyczny względny na bezwzględny
	add	rdi,	VARIABLE_KERNEL_PHYSICAL_ADDRESS

	; flaga, sukces
	clc

.end:
	; zwolnij dostęp do binarnej mapy pamięci
	mov	byte [variable_page_allocate_semaphore],	VARIABLE_EMPTY

	; przywróć oryginalne rejestry i flagi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; czyści zaalokowaną stronę wypełniając ją wartościami 0x0000000000000000
; IN:
;	rdi - adres strony do wyczyszczenia
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_page_clear:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; wyczyść stronę wartościami 0x0000000000000000
	xor	rax,	rax

	; ustaw licznik, rozmiar strony 4096 Bajtów / 8 Bajtów na rejestr
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE / 8

.loop:
	mov	qword [rdi],	rax
	mov	qword [rdi + 0x08],	rax
	mov	qword [rdi + 0x10],	rax
	mov	qword [rdi + 0x18],	rax
	mov	qword [rdi + 0x20],	rax
	mov	qword [rdi + 0x28],	rax
	mov	qword [rdi + 0x30],	rax
	mov	qword [rdi + 0x38],	rax

	; przesuń wskaźnik o rozmiar 8 rejestrów
	add	rdi,	0x40

	; wyczyszczono wszystko?
	sub	rcx,	8
	jnz	.loop

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; czyści N zaalokowanych stron wypełniając je wartościami 0x0000000000000000
; IN:
;	rcx - ilość ciągłych stron do wyczyszczenia
;	rdi - adres strony do wyczyszczenia
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_page_clear_few:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

.loop:
	; wyczyść stronę
	call	cyjon_page_clear

	; przesuń wskaźnik na następną stronę
	add	rdi,	VARIABLE_MEMORY_PAGE_SIZE

	; kontynuuj z pozostałymi stronami
	loop	.loop

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret

;=======================================================================
; procedura przekazuje wykorzystywaną stronę do puli wolnych
; IN:
;	rdi	- adres strony do zwolnienia
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_page_release:
	; zachowaj oryginalne rejestry i flagi
	push	rax
	push	rcx
	push	rdx
	push	rdi
	pushf

	; przelicz na adres względny
	sub	rdi,	VARIABLE_KERNEL_PHYSICAL_ADDRESS

	; przenieś bezwzględny adres fizyczny ramki do akumulatora
	mov	rax,	rdi
	; zamień na numer ramki
	shr	rax,	12

	; oblicz przesunięcie względem początku binarnej mapy pamięci
	xor	rdx,	rdx	; wyczyść resztę/"starszą część"
	mov	rcx,	64	; 64 bity na rejestr
	div	rcx	; rdx:rax / rcx

	; ustaw wskaźnik na początek binarnej mapy pamięci
	mov	rdi,	qword [variable_binary_memory_map_address_start]

	; dodaj do adresu wskaźnika przesunięcie
	shl	rax,	3	; zamień na Bajty
	add	rdi,	rax

	; wykonujemy "lustrzane odbicie" numeru pozycji bitu w rejestrze
	mov	rcx,	63	; przekształć wskaźnik bitu
	sub	rcx,	rdx	; w numer pozycji (lustrzane odbicie)

.wait:
	; czekaj na zwolnienie binarnej mapy pamięci
	cmp	byte [variable_page_allocate_semaphore],	VARIABLE_EMPTY
	jne	.wait

	; zarezerwuj binarną mapę pamięci
	mov	byte [variable_page_allocate_semaphore],	VARIABLE_TRUE

	; pobierz zestaw 64 bitów z binarnej mapy pamięci
	mov	rax,	qword [rdi]
	; ustaw bit odpowiadający za zwalnianą ramkę
	bts	rax,	rcx

	; zaaktualizuj binarną mapę pamięci
	stosq

	; zwiększamy ilość dostępnych stron o jedną
	inc	qword [variable_binary_memory_map_free]

	; zwolnij binarną mapę pamięci
	mov	byte [variable_page_allocate_semaphore],	VARIABLE_EMPTY

	; przywróć oryginalne rejestry i flagi
	popf
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; procedura rejestruje przestrzeń fizyczną znadującą się pod tym samym adresem logicznym
; IN:
;	eax	- adres przestrzeni fizycznej do opisania
;	ebx	- właściwości rekordów/stron
;	ecx	- ilość stron do opisania
;	edi	- adres fizyczny tablicy PML4 jądra/procesu
; OUT:
;	eax
;		VARIABLE_EMPTY	- ok
;		VARIABLE_TRUE	- brak wystarczającej ilości stron
;
; wszystkie rejestry zachowane
cyjon_page_map_physical_area:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdx
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
	push	rcx
	push	rax

.wait:
	; sprawdź czy binarna mapa pamięci jest dostępna do modyfikacji
	cmp	byte [variable_page_semaphore],	VARIABLE_TRUE
	je	.wait	; nie, czekaj na zwolnienie

	; zarezerwuj binarną mapę pamięci
	mov	byte [variable_page_semaphore],	VARIABLE_TRUE

	; oblicz wymaganą ilość wolnych stron do opisania przestrzeni
	call	cyjon_page_calculate_requirements

	; sprawdź czy istnieje odpowiednia ilość 
	cmp	qword [variable_binary_memory_map_free],	rcx
	jb	.no_memory

	; przywróć oryginalne rejestry
	pop	rax
	mov	rcx,	qword [rsp]

	; przygotuj procedure
	call	cyjon_page_prepare_pml_variables
	cmp	rdi,	VARIABLE_EMPTY
	je	.end

	; zapamiętaj właściwości
	mov	rdx,	rbx

	; połącz właściwości z adresem pierwszej strony fizycznej
	add	rbx,	rax

.record:
	; sprawdź czy tablica pml1 jest pełna
	cmp	r12,	512
	jb	.ok	; jeśli tak, utwórz nową tablicę pml1

	; utwórz nową tablicę pml1
	call	cyjon_page_new_pml1
	cmp	rdi,	VARIABLE_EMPTY

.ok:
	; załaduj adres i właściwości ramki do akumulatora
	mov	rax,	rbx

	; zapisz do rekordu tablicy pml1[r12]
	stosq

	; przesuń przesuń adres na nastepną ramkę
	add	rbx,	0x1000

	; sprzężenie zwrotne
	cmp	rcx,	1
	je	.end

	; ustaw numer następnego rekordu w tablicy pml1
	inc	r12

	; kontynuuj
	loop	.record

	; przestrzeń została opisana
	xor	rax,	rax

.end:
	; zwolnij binarną mapę pamięci
	mov	byte [variable_page_semaphore],	VARIABLE_FALSE

	; przywróć oryginalne rejestry
	pop	rcx
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rdx
	pop	rbx

	; powrót z procedury
	ret

.no_memory:
	; usuń zmienną z stosu
	add	rsp,	VARIABLE_QWORD_SIZE

	; brak wolnej pamięci
	mov	rax,	VARIABLE_TRUE

	; koniec
	jmp	.end

;===============================================================================
; procedura oblicza ilość wymaganych stron do opisania N stron
; IN:
;	rax	- ilość stron do opisania
;
; OUT:
;	rcx	- wynik
;
; pozostałe rejestry zachowane
cyjon_page_calculate_requirements:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx

	cmp	rcx,	512 * 512	; 1 GiB
	jb	.no_above_1GiB

	mov	rax,	512 * 512

	; sprawdź dostępność
	jmp	.calculated

.no_above_1GiB:
	cmp	rcx,	512	; 2 MiB
	jb	.no_above_2MiB

	mov	rax,	512

	; sprawdź dostępność
	jmp	.calculated

.no_above_2MiB:
	; na zarejestrowanie 1 ramki potrzeba min. 3 tablic PML + 3 tablice PML jeśli przekroczy zakres tablicy PML1
	add	rcx,	3 + 3

.calculated:
	; oblicz wielokrotność "kawałków"
	xchg	rax,	rcx
	xor	rdx,	rdx
	div	rcx

	; "zaokrąglij" w górę
	inc	rax

	; oblicz ilość wymaganych tablic PML do opisania przestrzeni
	mov	rcx,	3
	xor	rdx,	rdx
	mul	rcx

	; 3 tablice PML jeśli przekroczy zakres tablicy PML1
	add	rax,	3

	; zwróć wynik
	mov	rcx,	rax

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rax

	; powrót z procedury
	ret
;=======================================================================
; procedura przygotowuje niezbędne informacje o tablicach PML[4,3,2,1]
; IN:
;	rax	- adres przestrzeni fizycznej/logicznej do opisania
;	rbx	- właściwości rekordów/stron
;	r11	- adres fizyczny tablicy PML4 jądra/procesu
; OUT:
;	rdi	- wskaźnik rekordu w tablicy PML1 względem otrzymanego adresu fizycznego/logicznego
;
;	r8	- wskaźnik kolejnego wolnego rekordu w tablicy PML1
;	r9	- wskaźnik kolejnego wolnego rekordu w tablicy PML2
;	r10	- wskaźnik kolejnego wolnego rekordu w tablicy PML3
;	r11	- wskaźnik kolejnego wolnego rekordu w tablicy PML4
;
;	r12	- numer kolejnego wolnego rekordu w tablicy PML1
;	r13	- numer kolejnego wolnego rekordu w tablicy PML2
;	r14	- numer kolejnego wolnego rekordu w tablicy PML3
;	r15	- numer kolejnego wolnego rekordu w tablicy PML4
;
; OR OUT:
;	rdi	- VARIABLE_EMPTY jeśli brak wolnej pamięci
;
; pozostałe rejestry zachowane
cyjon_page_prepare_pml_variables:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	; jeśli brak dostępnej przestrzeni, rejestry zostaną przywrócone
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; oblicz numer rekordu w tablicy PML4 na podstawie otrzymanego adresu fizycznego/logicznego
	mov	rcx,	0x0000008000000000	; 512 GiB
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx	; RAX / RCX

	; zapamiętaj numer rekordu
	mov	r15,	rax

	; zamień wynik całkowity na przesunięcie adres rekordu wewnątrz tablicy PML4
	shl	rax,	3	; * 8

	; przesuń adres tablicy PML4 na odpowiedni rekord
	add	r11,	rax

	; sprawdź czy rekord PML4 zawieta adres tablicy PML3
	cmp	qword [r11],	VARIABLE_EMPTY
	je	.no_pml3

	; pobierz adres tablicy PML3 z rekordu tablicy PML4
	mov	rax,	qword [r11]

	; usuń właściwości strony/rekordu z adresu tablicy PML3
	xor	al,	al

	; zapisz adres tablicy PML3
	mov	r10,	rax

	; przejdź do dalszych obliczeń
	jmp	.pml3_table

.no_pml3:
	; przygotuj miejsce na tablicę PML3
	mov	dl,	4	; flaga/numer tablicy PML gdzie jesteśmy
	call	cyjon_page_allocate
	cmp	rdi,	VARIABLE_EMPTY
	je	.no_memory	; brak dostępnych stron

	; zwiększono rozmiar stronicowania
	inc	qword [variable_binary_memory_map_paged]

	; wyczyść stronę
	call	cyjon_page_clear

	; zapisz adres tablicy PML3
	mov	r10,	rdi

	; ustaw właściwości strony w rekordzie tablicy PML3
	or	di,	bx

	; zapisz wartość tablicy PML3 do rekordu tablicy PML4
	mov	qword [r11],	rdi

.pml3_table:
	; ustaw numer kolejnego wolnego rekordu w tablicy PML4
	inc	r15

	; ustaw wskaźnik kolejnego wolnego rekordu w tablicy PML4
	add	r11,	0x08

	; oblicz numer rekordu w PML3
	mov	rax,	rdx	; załaduj resztę z poprzedniego dzielenia
	mov	rcx,	0x0000000040000000	; 1 GiB
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx	; RAX / RCX

	; zapamiętaj numer rekordu
	mov	r14,	rax

	; zamień wynik całkowity na przesunięcie wew. tablicy PML3
	shl	rax,	3	; rax*8

	; ustaw wskaźnik na rekord w tablicy PML3
	add	r10,	rax

	; sprawdź czy istnieje tablica PML2
	cmp	qword [r10],	VARIABLE_EMPTY
	je	.no_pml2

	; pobierz adres tablicy PML2 z rekordu tablicy PML3
	mov	rax,	qword [r10]

	; usuń właściwości strony/rekordu z adresu tablicy PML2
	xor	al,	al

	; zapisz adres tablicy PML2
	mov	r9,	rax

	; przejdź do dalszych obliczeń
	jmp	.pml2_table

.no_pml2:
	; przygotuj miejsce na tablicę PML2
	mov	dl,	3	; flaga/numer tablicy PML gdzie jesteśmy
	call	cyjon_page_allocate
	cmp	rdi,	VARIABLE_EMPTY
	je	.no_memory	; brak dostępnych stron

	; zwiększono rozmiar stronicowania
	inc	qword [variable_binary_memory_map_paged]

	; wyczyść stronę
	call	cyjon_page_clear

	; zapisz adres tablicy PML2
	mov	r9,	rdi

	; ustaw właściwości strony w rekordzie tablicy PML2
	or	di,	bx

	; zapisz wartość tablicy PML2 do rekordu tablicy PML3
	mov	qword [r10],	rdi

.pml2_table:
	; ustaw numer kolejnego wolnego rekordu w tablicy PML3
	inc	r14

	; ustaw wskaźnik kolejnego wolnego rekordu w tablicy PML3
	add	r10,	0x08

	; oblicz numer rekordu w PML2
	mov	rax,	rdx	; załaduj resztę z poprzedniego dzielenia
	mov	rcx,	0x0000000000200000	; 2 MiB
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx	; RAX / RCX

	; zapamiętaj numer rekordu
	mov	r13,	rax

	; zamień wynik całkowity na przesunięcie wew. tablicy PML2
	shl	rax,	3	; rax*8

	; ustaw wskaźnik na rekord w tablicy PML2
	add	r9,	rax

	; sprawdź czy istnieje tablica PML1
	cmp	qword [r9],	VARIABLE_EMPTY
	je	.no_pml1

	; pobierz adres tablicy PML1 z rekordu tablicy PML2
	mov	rax,	qword [r9]

	; usuń właściwości strony/rekordu z adresu tablicy PML1
	xor	al,	al

	; zapisz adres tablicy PML1
	mov	r8,	rax

	; przejdź do dalszych obliczeń
	jmp	.pml1_table

.no_pml1:
	; przygotuj miejsce na tablicę PML1
	call	cyjon_page_allocate
	mov	dl,	2	; flaga/numer tablicy PML gdzie jesteśmy
	cmp	rdi,	VARIABLE_EMPTY
	je	.no_memory	; brak dostępnych stron

	; zwiększono rozmiar stronicowania
	inc	qword [variable_binary_memory_map_paged]

	; wyczyść stronę
	call	cyjon_page_clear

	; zapisz adres tablicy PML1
	mov	r8,	rdi

	; ustaw właściwości strony w rekordzie tablicy PML1
	or	di,	bx

	; zapisz wartość tablicy pml1 do rekordu tablicy PML2
	mov	qword [r9],	rdi

.pml1_table:
	; ustaw numer kolejnego wolnego rekordu w tablicy PML2
	inc	r13

	; ustaw wskaźnik kolejnego wolnego rekordu w tablicy PML2
	add	r9,	0x08

	; oblicz numer rekordu w PML1
	mov	rax,	rdx	; załaduj resztę z poprzedniego dzielenia
	mov	rcx,	0x0000000000001000	; 4 KiB
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx	; RAX / RCX

	; zapamiętaj numer rekordu
	mov	r12,	rax

	; zamień wynik całkowity na przesunięcie wew. tablicy PML1
	shl	rax,	3	; * 8

	; ustaw wskaźnik na rekord w tablicy PML1
	add	r8,	rax

	; załaduj wskaźnik do rekordu tablicy PML1
	mov	rdi,	r8

	; usuń kopie rejestrów (udało się zaalokować tablice PML)
	add	rsp,	0x08 * 8

.end:
	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

.no_memory:
	; licznik rekordów
	mov	rcx,	512

	; załaduj adres aktualnego rekordu w tablicy PML2
	mov	rdi,	r9
	mov	rax,	r10	; i tablicy nadrzędnej

	; czy tablica PML2 jest pusta
	cmp	dl,	2
	je	.unallocate_pml

	; załaduj adres aktualnego rekordu w tablicy PML3
	mov	rdi,	r10
	mov	rax,	r11	; i tablicy nadrzędnej

	; czy tablica PML3 jest pusta
	cmp	dl,	3
	je	.unallocate_pml

.no_memory_end:
	; przywróć oryginalne rejestry
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8

	; zwróć informacje o braku odpowiedniej ilości stron by zaalokować daną przestrzeń
	xor	rdi,	rdi

	; koniec procedury
	jmp	.end

.unallocate_pml:
	; usuń numer rekordu
	and	di,	0xF000

	; zachowaj adres
	push	rdi

.loop:
	; rekord pusty?
	cmp	qword [rdi],	VARIABLE_EMPTY
	je	.empty

	; usuń zmienną lokalną
	pop	rdi

	; tablica zawiera nieznane rekordy, brak możliwości zwolnienia strony
	jmp	.no_memory_end

.empty:
	loop	.loop

	; przywróć adres
	pop	rdi

	; zwolnij stronę
	call	cyjon_page_release

	; zmniejszono rozmiar stronicowania
	dec	qword [variable_binary_memory_map_paged]

	; usuń rekord z tablicy nadrzędnej
	mov	qword [rax],	VARIABLE_EMPTY

	; kontynuuj z następną tablicą
	inc	dl
	jmp	.no_memory

;=======================================================================
; PODPROCEDURA tworzy nową tablicę PML1 o podanym adresie logicznym
; IN:
;	rax	- adres przestrzeni fizycznej/logicznej do opisania
;	rbx	- właściwości rekordów/stron
;
;	r8	- wskaźnik kolejnego wolnego rekordu w tablicy PML1
;	r9	- wskaźnik kolejnego wolnego rekordu w tablicy PML2
;	r10	- wskaźnik kolejnego wolnego rekordu w tablicy PML3
;	r11	- wskaźnik kolejnego wolnego rekordu w tablicy PML4
;
;	r12	- numer kolejnego wolnego rekordu w tablicy PML1
;	r13	- numer kolejnego wolnego rekordu w tablicy PML2
;	r14	- numer kolejnego wolnego rekordu w tablicy PML3
;	r15	- numer kolejnego wolnego rekordu w tablicy PML4
;
; OUT:
;	rdi	- wskaźnik rekordu w tablicy PML1 względem otrzymanego adresu fizycznego/logicznego
;
; IF CHANGED:
;	r8	- wskaźnik kolejnego wolnego rekordu w tablicy PML1
;	r9	- wskaźnik kolejnego wolnego rekordu w tablicy PML2
;	r10	- wskaźnik kolejnego wolnego rekordu w tablicy PML3
;	r11	- wskaźnik kolejnego wolnego rekordu w tablicy PML4
;
;	r12	- numer kolejnego wolnego rekordu w tablicy PML1
;	r13	- numer kolejnego wolnego rekordu w tablicy PML2
;	r14	- numer kolejnego wolnego rekordu w tablicy PML3
;	r15	- numer kolejnego wolnego rekordu w tablicy PML4
;
; pozostałe rejestry zachowane
cyjon_page_new_pml1:
	; sprawdź czy tablica pml2 jest pełna
	cmp	r13,	512
	je	.pml3	; jeśli tak, utwórz nową tablicę pml2

	; pobierz nastepny rekord z tablicy pml2
	mov	rdi,	qword [r9]

	; sprawdź czy jest już opisany
	cmp	rdi,	VARIABLE_EMPTY
	je	.continue_pml2	; jesli nie

	; usuń właściwości z adresu tablicy pml1
	and	di,	0xF000

	; zapamiętaj adres tablicy pml1
	mov	r8,	rdi

	; zresetuj numer rekordu w tablicy pml1
	xor	r12,	r12

	; pomiń tworzenie nowej tablicy pml1
	jmp	.leave_pml2

.continue_pml2:
	; przygotuj miejsce na tablicę PML1
	call	cyjon_page_allocate

	; sprawdź czy zaalokowano stronę
	cmp	rdi,	VARIABLE_EMPTY
	je	.no_memory

	; zwiększono rozmiar stronicowania
	inc	qword [variable_binary_memory_map_paged]

	; wyczyść stronę
	call	cyjon_page_clear

	; zapamiętaj adres tablicy pml1
	mov	r8,	rdi

	; zresetuj numer rekordu w tablicy pml1
	xor	r12,	r12

	; ustaw właściwości tablicy pml1
	or	di,	dx

	; podepnij tablice pml1 pod rekord tablicy pml2[r13]
	mov	qword [r9],	rdi

	; usuń właściwości z adresu tablicy pml1
	and	di,	0xF000

.leave_pml2:
	; ustaw numer następnego rekordu w tablicy pml2
	inc	r13

	; ustaw wskaźnik następnego rekordu w tablicy pml2
	add	r9,	 0x08

	; kontynuuj
	ret

.pml3:
	; sprawdź czy tablica pml3 jest pełna
	cmp	r14,	512
	je	.pml4	; jeśli tak, utwórz nową tablicę pml3

	; pobierz nastepny rekord z tablicy pml3
	mov	rdi,	qword [r10]

	; sprawdź czy jest już opisany
	cmp	rdi,	VARIABLE_EMPTY
	je	.continue_pml3	; jesli nie

	; usuń właściwości z adresu tablicy pml2
	and	di,	0xF000

	; zapamiętaj adres tablicy pml2
	mov	r9,	rdi

	; zresetuj numer rekordu w tablicy pml2
	xor	r13,	r13

	; pomiń tworzenie nowej tablicy pml1
	jmp	.leave_pml3

.continue_pml3:
	; przygotuj miejsce na tablicę PML2
	call	cyjon_page_allocate

	; sprawdź czy zaalokowano stronę
	cmp	rdi,	VARIABLE_EMPTY
	je	.no_memory

	; zwiększono rozmiar stronicowania
	inc	qword [variable_binary_memory_map_paged]

	; wyczyść stronę
	call	cyjon_page_clear

	; zapamiętaj adres tablicy pml2
	mov	r9,	rdi

	; zresetuj numer rekordu w tablicy pml2
	xor	r13,	r13

	; ustaw właściwości tablicy pml2
	or	di,	dx

	; podepnij tablice pml2 pod rekord tablicy pml3[r14]
	mov	qword [r10],	rdi

.leave_pml3:
	; ustaw numer następnego rekordu w tablicy pml3
	inc	r14

	; ustaw wskaźnik następnego rekordu w tablicy pml3
	add	r10,	 0x08

	; kontynuuj
	jmp	cyjon_page_new_pml1

.pml4:
	; sprawdź czy tablica pml4 jest pełna
	cmp	r15,	512
	je	.pml4_panic	; jeśli tak, utwórz nową tablicę pml5, o cholewcia!

	; pobierz nastepny rekord z tablicy pml4
	mov	rdi,	qword [r11]

	; sprawdź czy jest już opisany
	cmp	rdi,	VARIABLE_EMPTY
	je	.continue_pml4	; jesli nie

	; usuń właściwości z adresu tablicy pml3
	and	di,	0xF000

	; zapamiętaj adres tablicy pml3
	mov	r10,	rdi

	; zresetuj numer rekordu w tablicy pml3
	xor	r14,	r14

	; pomiń tworzenie nowej tablicy pml3
	jmp	.leave_pml4

.continue_pml4:
	; przygotuj miejsce na tablicę PML3
	call	cyjon_page_allocate

	; sprawdź czy zaalokowano stronę
	cmp	rdi,	VARIABLE_EMPTY
	je	.no_memory

	; zwiększono rozmiar stronicowania
	inc	qword [variable_binary_memory_map_paged]

	; wyczyść stronę
	call	cyjon_page_clear

	; zapamiętaj adres tablicy pml3
	mov	r10,	rdi

	; zresetuj numer rekordu w tablicy pml3
	xor	r14,	r14

	; ustaw właściwości tablicy pml3
	or	di,	dx

	; podepnij tablice pml3 pod rekord tablicy pml4[r15]
	mov	qword [r11],	rdi

.leave_pml4:
	; ustaw numer następnego rekordu w tablicy pml4
	inc	r15

	; ustaw wskaźnik następnego rekordu w tablicy pml4
	add	r11,	 0x08

	; kontynuuj
	jmp	.pml3

.no_memory:
	

.pml4_panic:
	; tablica PML4 została przepełniona, błąd krytyczny jądra systemu
	mov	rsi,	text_kernel_panic_page_pml4
	jmp	cyjon_screen_kernel_panic

;=======================================================================
; procedura udostępnia przestrzeń logiczną podpinając wolne strony z pamięci fizycznej
; IN:
;	rax	- adres przestrzeni logicznej do opisania
;	rbx	- właściwości rekordów/stron
;	rcx	- ilość ramek do opisania
;	r11	- adres fizyczny tablicy PML4 jądra/procesu
; OUT:
;	rax	- kod błędu, ZERO jeśli OK
;	r8	- adres ostatnio mapowanej strony z tablicy PML1
;
; pozostałe rejestry zachowane
cyjon_page_map_logical_area:
	; zachowaj oryginalne rejestry
	push	rdi
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
	push	rcx

.wait:
	; sprawdź czy binarna mapa pamięci jest dostępna do modyfikacji
	cmp	byte [variable_page_semaphore],	VARIABLE_TRUE
	je	.wait	; nie, czekaj na zwolnienie

	; zarezerwuj binarną mapę pamięci
	mov	byte [variable_page_semaphore],	VARIABLE_TRUE

	; oblicz wymaganą ilość wolnych stron do opisania przestrzeni
	call	cyjon_page_calculate_requirements

	; dodaj rozmiar przestrzeni
	add	rcx,	qword [rsp]

	; sprawdź czy istnieje odpowiednia ilość 
	cmp	qword [variable_binary_memory_map_free],	rcx
	jb	.no_memory

	; przywróć oryginalny rejestr
	mov	rcx,	qword [rsp]

	; przygotuj zmienne
	call	cyjon_page_prepare_pml_variables

.loop:
	; sprawdź czy tablica PML1 jest pełna
	cmp	r12,	512
	jb	.ok	; jeśli tak, utwórz nową tablicę PML1

	; utwórz nową tablicę PML1
	call	cyjon_page_new_pml1

.ok:
	; sprawdź czy rekord jest już zarezerwowany
	cmp	qword [rdi],	VARIABLE_EMPTY
	je	.continue

	; przesuń wskaźnik na następy rekord
	add	rdi,	0x08

	; następna strona
	jmp	.leave

.continue:
	; zachowaj
	push	rdi

	; pobierz adres strony do opisania w przestrzeni logicznej
	call	cyjon_page_allocate
	call	cyjon_page_clear

	; zapamiętaj adres strony
	mov	rax,	rdi

	; przywróć
	pop	rdi

	; ustaw flagi
	or	ax,	bx
	stosq	; zapisz do tablicy PML1[r12]

	; sprzężenie zwrotne
	; jeśli jest to ostatnia ramka do opisania i zarazem ostatnia jednocześnie w tablicach PML1,2,3 oraz 4
	; może wystąpić przepełnienie stronicowania, jeśli nie wykona się testu ilości pozostałych ramek
	cmp	rcx,	0x0000000000000001
	je	.no_error

.leave:
	; zwiększ ilość rekordów przechowywanych w tablicy PML1
	inc	r12

	; opisz następne strony w tablicy PML1
	loop	.loop

.no_error:
	; przydzielono pamięć
	xor	rax,	rax

.end:
	; zwolnij binarną mapę pamięci
	mov	byte [variable_page_semaphore],	VARIABLE_FALSE

	; przywróć oryginalne rejestry
	pop	rcx
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	rdi

	; powrót z procedury
	ret

.no_memory:
	; brak dostępnej ilości pamięci
	mov	rax,	VARIABLE_TRUE

	; koniec
	jmp	.end
