;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_service:
	; zachowaj oryginalne rejestry
	push	rbp
	push	rax

	; zresetuj Direction Flag
	cld

	; usługa związana z procesem?
	cmp	al,	KERNEL_SERVICE_PROCESS
	je	.process	; tak

	; obsługa wirtualnego systemu plików?
	cmp	al,	KERNEL_SERVICE_VFS
	je	.vfs	; tak

	; obsługa systemu?
	cmp	al,	KERNEL_SERVICE_SYSTEM
	je	.system	; tak

.error:
	; flaga, błąd
	stc

.end:
	; pobierz aktualne flagi procesora
	pushf
	pop	rax

	; zwróć flagi do procesu
	mov	qword [rsp + KERNEL_TASK_STRUCTURE_IRETQ.eflags + STATIC_QWORD_SIZE_byte * 0x02],	rax

	; przywróć oryginalne rejestry
	pop	rax
	pop	rbp

	; koniec obsługi przerwania programowego
	iretq

	macro_debug	"kernel_service"

;===============================================================================
.process:
	; zakończ pracę procesu?
	cmp	ax,	KERNEL_SERVICE_PROCESS_exit
	je	kernel_task_kill	; tak

	; uruchomić nowy proces?
	cmp	ax,	KERNEL_SERVICE_PROCESS_run
	je	.process_run	; tak

	; czy proces istnieje?
	cmp	ax,	KERNEL_SERVICE_PROCESS_check
	je	.process_check	; tak

	; przydzielić przestrzeń pamięci?
	cmp	ax,	KERNEL_SERVICE_PROCESS_memory_alloc
	je	.process_memory_alloc	; tak

	; odebrać komunikat przeznaczony dla procesu?
	cmp	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	je	.process_ipc_receive	; tak

	; wysłać komunikat do innego procesu?
	cmp	ax,	KERNEL_SERVICE_PROCESS_ipc_send
	je	.process_ipc_send	; tak

	; wysłać komunikat do rodzica?
	cmp	ax,	KERNEL_SERVICE_PROCESS_ipc_send_to_parent
	je	.process_ipc_send_parent	; tak

	; zwrócić PID procesu?
	cmp	ax,	KERNEL_SERVICE_PROCESS_pid
	je	.process_pid	; tak

	; zwrócić PID procesu rodzica?
	cmp	ax,	KERNEL_SERVICE_PROCESS_pid_parent
	je	.process_pid_parent	; tak

	; przesłać ciąg znaków na standardowe wyjście?
	cmp	ax,	KERNEL_SERVICE_PROCESS_stream_out
	je	.process_stream_out	; tak

	; pobrać ciąg znaków z standardowego wejście?
	cmp	ax,	KERNEL_SERVICE_PROCESS_stream_in
	je	.process_stream_in	; tak

	; przesłać jeden Bajt na standardowe wyjście?
	cmp	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	je	.process_stream_out_char	; tak

	; przetworzyć meta dane strumienia?
	cmp	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	je	.process_stream_meta	; tak

	; zwrócić listę uruchomionych procesów?
	cmp	ax,	KERNEL_SERVICE_PROCESS_list
	je	.process_list	; tak

	; zwolnić przestrzeń procesu?
	cmp	ax,	KERNEL_SERVICE_PROCESS_memory_release
	je	.process_memory_release	; tak

	; zatrzymać proces na dany czas?
	cmp	ax,	KERNEL_SERVICE_PROCESS_sleep
	je	.process_sleep	; tak

	; zwolnić pozostały czas procesora?
	cmp	ax,	KERNEL_SERVICE_PROCESS_release
	je	.process_release	; tak

	; zmienić katalog roboczy procesu?
	cmp	ax,	KERNEL_SERVICE_PROCESS_dir_change
	je	.process_dir_change	; tak

	; koniec obsługi podprocedury
	jmp	kernel_service.error

;-------------------------------------------------------------------------------
; wyjście:
;	rcx - PID procesu rodzica
.process_pid_parent:
	; zachowaj oryginalne rejestry
	push	rdi

	; zwróć PID rodzica
	call	kernel_task_active
	mov	rcx,	qword [rdi + KERNEL_TASK_STRUCTURE.parent]

	; przywróć oryginalne rejestry
	pop	rdi

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_pid_parent"

;-------------------------------------------------------------------------------
; wejście:
;	bl - zachowanie strumienia procesu
;	rcx - ilość znaków w ścieżce do pliku
;	rsi - wskaźnik do ciągu znaków reprezentujących ścieżkę do pliku
;	r8 - rozmiar argumentów w Bajtach
; wyjście:
;	rcx - PID uruchomionego procesu
.process_run:
	; zachowaj oryginalne rejestry
	push	rsi
	push	rdi
	push	rcx

	; rozwiąż ścieżkę do programu
	call	kernel_vfs_path_resolve
	jc	.process_run_end	; błąd, niepoprawna ścieżka

	; odszukaj program w danym katalogu
	call	kernel_vfs_file_find
	jc	.process_run_end	; błąd, pliku nie znaleziono

	; uruchom program
	; rcx - ilość znaków reprezentujących nazwę uruchamianego programu
	; rsi - wskaźnik do nazwy programu wraz z argumentami
	; rdi - wskaźnik do supła pliku
	; r8 - rozmiar argumentów w Bajtach
	call	kernel_exec
	jc	.process_run_end	; program dodany do kolejki zadań

	; zwróć identyfikator uruchomionego procesu
	mov	qword [rsp],	rcx

	; przygotuj potoki
	call	kernel_stream_set
	jc	.process_run_end	; nie udało się podłączyć strumieni we/wy

	; oznacz proces jako gotowy do przetwarzania
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active

.process_run_end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rdi
	pop	rsi

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_run"

;-------------------------------------------------------------------------------
.process_check:
	; odszukaj proces w kolejce zadań
	call	kernel_task_pid_check

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_check"

;-------------------------------------------------------------------------------
; wejście:
;	rcx - rozmiar przestrzeni do zaalokowania
;	rdi - wskaźnik do przestrzeni jądra systemu
; wyjście:
;	Flaga CF - jeśli brak miejsca
;	rdi - wskaźnik do zaalokowanej przestrzeni
.process_memory_alloc:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	r8
	push	r11
	push	rax
	push	rdi

	; zamień rozmiar przestrzeni na strony
	call	library_page_from_size

	; przydziel przestrzeń pamięci o podanym rozmiarze dla procesu
	call	kernel_memory_alloc_task

	; zwróć adres przydzielonej przestrzeni
	mov	qword [rsp],	rdi

.process_memory_alloc_end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rax
	pop	r11
	pop	r8
	pop	rcx
	pop	rbx

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_memory_alloc"

;-------------------------------------------------------------------------------
; wejście:
;	rdi - wskaźnik miejsca przeznaczenia komunikatu
; wyjście:
;	Flaga CF, jeśli brak komunikatu
.process_ipc_receive:
	; pobierz komunikat przeznaczony dla procesu
	call	kernel_ipc_receive

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_ipc_receive"

;-------------------------------------------------------------------------------
; wejście:
;	rbx - PID procesu docelowego
;	ecx - rozmiar przestrzeni w Bajtach lub jeśli wartość pusta, 40 Bajtów z pozycji wskaźnika RSI
;	rsi - wskaźnik do przestrzeni danych
; wyjście:
;	Flaga CF - jeśli kolejka przepełniona
.process_ipc_send:
	; wyślij komunikat do procesu
	call	kernel_ipc_insert

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_ipc_send"

;-------------------------------------------------------------------------------
; wejście:
;	ecx - rozmiar przestrzeni w Bajtach lub jeśli wartość pusta, 40 Bajtów z pozycji wskaźnika RSI
;	rsi - wskaźnik do przestrzeni danych
; wyjście:
;	Flaga CF - jeśli kolejka przepełniona
.process_ipc_send_parent:
	; zachowaj oryginalne rejestry
	push	rdi

	; pobierz PID procesu rodzica
	call	kernel_task_active
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.parent]

	; przywróć oryginalne rejestry
	pop	rdi

	; wyślij komunikat do procesu
	call	kernel_ipc_insert

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_ipc_send_parent"

;-------------------------------------------------------------------------------
; wyjście:
;	rax - pid procesu
.process_pid:
	; pobierz PID procesu
	call	kernel_task_active_pid

	; zwróć do procesu
	mov	qword [rsp],	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_pid"

;-------------------------------------------------------------------------------
; wejście:
;	rcx - rozmiar ciągu w Bajtach
;	rsi - wskaźnik do ciągu znaków
.process_stream_out:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdi

	; brak ciągu dla strumienia?
	test	rcx,	rcx
	jz	.process_stream_out_end	 ; tak

	; pobierz identyfikator strumienia wyjścia procesu
	call	kernel_task_active
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.out]

	; wyślij ciąg znaków na standardowe wyjście
	call	kernel_stream_insert

.process_stream_out_end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rbx

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_stream_out"

;-------------------------------------------------------------------------------
; wejście:
;	rdi - wskaźnik do przestrzeni bufora
; wyjście:
;	Flaga ZF - jeśli brak danych
;	rcx - ilość przesłanych danych
.process_stream_in:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdi

	; pobierz identyfikator strumienia wejścia procesu
	call	kernel_task_active
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.in]

	; wyślij ciąg znaków na standardowe wyjście
	pop	rdi	; przywróć adres docelowy bufora procesu
	call	kernel_stream_receive

	; brak danych?
	test	rcx,	rcx

	; przywróć oryginalny rejestr
	pop	rbx

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_stream_in"

;-------------------------------------------------------------------------------
; wejście:
;	rcx - ile kopii znaku wysłać
;	dl - wartość
.process_stream_out_char:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi
	push	rdi
	push	rdx	; pozostaw znak na stosie

	; brak znków do wysłania na strumień?
	test	rcx,	rcx
	jz	.process_stream_out_char_end	; tak

	; pobierz identyfikator strumienia wyjścia procesu
	call	kernel_task_active
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.out]

	; wyświetl znak N razy
	mov	rdx,	rcx
	mov	ecx,	STATIC_BYTE_SIZE_byte
	mov	rsi,	rsp

.process_stream_out_char_loop:
	; wyślij wartość na standardowe wyjście
	call	kernel_stream_insert

	; wysłano wszystkie kopie znaku?
	dec	rdx
	jnz	.process_stream_out_char_loop	; nie

.process_stream_out_char_end:
	; przywróć oryginalne rejestry
	pop	rdx	; przywróć znak z stosu
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_stream_out_char"

;===============================================================================
; wejście:
;	bl - odczyt lub zapis
;	rsi - wskaźnik źródłowy danych
;	lub
;	rdi - wskaźnik docelowy danych
.process_stream_meta:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; rozmiar przestrzeni meta
	mov	rcx,	KERNEL_STREAM_META_SIZE_byte

	; ustaw wskaźnik na właściwości procesu
	call	kernel_task_active

	; domyślny strumień: wyjście
	mov	rdx,	qword [rdi + KERNEL_TASK_STRUCTURE.out]

	; strumień wyjścia?
	test	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_out
	jnz	.process_stream_meta_selected	; tak

	; wybierz strumień: wejście
	mov	rdx,	qword [rdi + KERNEL_TASK_STRUCTURE.in]

.process_stream_meta_selected:
	; zapisać dane?
	test	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_set
	jz	.process_stream_meta_read	; nie

	; zapisz dane do meta strumienia
	mov	rdi,	rdx
	add	rdi,	KERNEL_STREAM_STRUCTURE_ENTRY.meta
	rep	movsb

	; podnieś flagę, meta dane aktualne
	or	byte [rdx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_meta

	; koniec obsługi
	jmp	.process_stream_meta_end

.process_stream_meta_read:
	; meta dane są aktualne?
	test	byte [rdx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_meta
	jz	.process_stream_meta_error

	; wyślij do procesu meta dane
	mov	rsi,	rdx
	add	rsi,	KERNEL_STREAM_STRUCTURE_ENTRY.meta
	mov	rdi,	qword [rsp]
	rep	movsb

	; koniec obsługi procedury
	jmp	.process_stream_meta_end

.process_stream_meta_error:
	; flaga, błąd
	stc

.process_stream_meta_end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_stream_meta"

;-------------------------------------------------------------------------------
; wyjście:
;	rbx - ilość wpisów
;	rcx - rozmiar listy w Bajtach
;	rsi - wskaźnik do przestrzeni listy
.process_list:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi
	push	rcx

	; przydziel przestrzeń dla procesu
	mov	rcx,	qword [kernel_task_size_page]
	call	kernel_memory_alloc_task
	jc	.process_list_end	; brak dostępnej przestrzeni

	; zachowaj wskaźnik początku i rozmiaru przestrzeni
	push	rcx
	push	rdi

	; ilość wpisów przesłanych do procesu
	xor	ebx,	ebx

	; uzupełnij listę o wszystkie procesy zarejetrowane w serpentynie
	mov	rsi,	qword [kernel_task_address]

.process_list_reload:
	; ilość wpisów na blok serpentyny
	mov	cl,	STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

.process_list_loop:
	; wpis jest pusty?
	cmp	word [rsi + KERNEL_TASK_STRUCTURE.flags],	STATIC_EMPTY
	je	.process_list_next	; tak

	; proces jest aktywny?
	test	word [rsi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active
	jz	.process_list_next	; nie, zignoruj

	; zachowaj wskaźnik i ilość wpisów do przetworzenia w bloku serpentyny
	push	rcx
	push	rsi

	; wyślij dedykowane informacje o procesie

	; PID procesu
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.pid]
	stosq

	; PID rodzica
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.parent]
	stosq

	; numer procesora logicznego przetwarzajcego proces
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.cpu]
	stosq

	; czas uruchomienia procesu w formacie Microtime
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.time]
	stosq

	; niewykorzystany czas procesora w formacie APIC
	mov	eax,	dword [rsi + KERNEL_TASK_STRUCTURE.apic]
	stosd

	; rozmiar wykorzystanej przestrzeni pamięci przez proces (bez tablic stronicowania)
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.memory]
	stosq

	; supeł katalogu roboczego procesu
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.knot]
	stosq

	; flagi stanu procesu
	mov	ax,	word [rsi + KERNEL_TASK_STRUCTURE.flags]
	stosw

	; ilość znaków reprezentujących nazwę procesu
	movzx	eax,	byte [rsi + KERNEL_TASK_STRUCTURE.length]
	stosb

	; nazwa procesu
	mov	ecx,	eax
	add	rsi,	KERNEL_TASK_STRUCTURE.name
	rep	movsb

	; przywróć wskaźnik i ilość wpisów do przetworzenia w bloku serpentyny
	pop	rsi
	pop	rcx

	; załądowano informacje o procesie
	inc	rbx

.process_list_next:
	; następny wpis z listy
	add	rsi,	KERNEL_TASK_STRUCTURE.SIZE

	; koniec wpisów w bloku?
	dec	cl
	jnz	.process_list_loop	; nie

	; pobierz adres następnego bloku serpentyny
	and	si,	STATIC_PAGE_mask
	mov	rsi,	qword [rsi + STATIC_STRUCTURE_BLOCK.link]

	; koniec serpentyny?
	cmp	rsi,	qword [kernel_task_address]
	jne	.process_list_reload	; nie

	; zwróć adres przestrzeni listy procesów
	pop	rsi
	pop	rcx	; i jej rozmiar w Bajtach
	shl	rcx,	STATIC_MULTIPLE_BY_PAGE_shift
	mov	qword [rsp],	rcx

.process_list_end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rdi
	pop	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_list"

;===============================================================================
; wejście:
;	rcx - rozmiar przestrzeni w Bajtach
;	rdi - wskaźnik do przestrzeni
.process_memory_release:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	r11
	push	rdi

	; adres przestrzeni do zwolnienia
	mov	rax,	KERNEL_MEMORY_HIGH_mask
	xchg	rdi,	rax
	sub	rax,	rdi	; zamień na rzeczywisty

	; tablica stronicowania procesu
	mov	r11,	cr3

	; rozmiar przestrzeni w stronach
	call	library_page_from_size

	; zwolnij przestrzeń
	call	kernel_memory_release_foreign

	; zwolnij przestrzeń w binarnej mapie pamięci procesu
	mov	rdi,	qword [rsp]
	call	kernel_memory_release_task_secured

	; przywróć oryginalne rejestry
	pop	rdi
	pop	r11
	pop	rcx
	pop	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_memory_release"

;-------------------------------------------------------------------------------
; wejście:
;	rcx - ilość milisekund
;	1 sekunda = 1024 cykli mikrotime
.process_sleep:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; pobierz wskaźnik procesu
	call	kernel_task_active

	; oznacz proces w stanie uśpienia
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_sleep

	; ustaw czas wybudzenia procesu
	add	rcx,	qword [driver_rtc_microtime]

.process_sleep_wait:
	; wywłaszczenie
	int	KERNEL_APIC_IRQ_number

	; wybudzić proces?
	cmp	rcx,	qword [driver_rtc_microtime]
	ja	.process_sleep_wait	; nie

	; usuń informację o uśpieniu procesu
	and	word [rdi + KERNEL_TASK_STRUCTURE.flags],	~KERNEL_TASK_FLAG_sleep

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_sleep"

;-------------------------------------------------------------------------------
.process_release:
	; wywłaszczenie
	int	KERNEL_APIC_IRQ_number

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_release"

;-------------------------------------------------------------------------------
; wejście:
;	rcx - ilość znaków w ciągu
;	rsi - wskaźnik do ciągu znaków
.process_dir_change:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; rozwiąż ścieżkę do pliku
	call	kernel_vfs_path_resolve
	jc	.process_dir_change_end	; nie udało sie rozwiązać ścieżki do ostatniego pliku

	; odszukaj plik w katalogu docelowym
	call	kernel_vfs_file_find
	jc	.process_dir_change_end	; nie znaleziono podanego katalogu, lub plik nie jest katalogiem

.process_dir_change_smybolic_link:
	; odnaleziony plik jest dowiązaniem symbolicznym?
	test	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_symbolic_link
	jz	.process_dir_change_ok	; nie

	; rozwiąż dowiązanie
	mov	rdi,	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

	; sprawdź raz jeszcze
	jmp	.process_dir_change_smybolic_link

.process_dir_change_ok:
	; plik jest typu: katalog?
	test	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_directory
	jz	.process_dir_change_error	; nie

	; zachowaj wskaźnik do supła katalogu
	mov	rax,	rdi

	; ustaw wskaźnik na zadanie procesora logicznego
	call	kernel_task_active

	; zachowaj informacje o nowym katalogu roboczym procesu
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.knot],	rax

	; koniec obsługi polecenia
	jmp	.process_dir_change_end

.process_dir_change_error:
	; flaga, błąd
	stc

.process_dir_change_end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_dir_change"

;===============================================================================
.vfs:
	; sprawdzić poprawność ścieżki?
	cmp	ax,	KERNEL_SERVICE_VFS_exist
	je	.vfs_exist	; tak

	; utworzyć pusty plik?
	cmp	ax,	KERNEL_SERVICE_VFS_touch
	je	.vfs_touch	; tak

	; zwrócić listę plików z podanej ścieżki?
	cmp	ax,	KERNEL_SERVICE_VFS_dir
	je	.vfs_dir	; tak

	; wczytać zawartość pliku?
	cmp	ax,	KERNEL_SERVICE_VFS_read
	je	.vfs_read	; tak

	; zapisać ciąg danych do pliku?
	cmp	ax,	KERNEL_SERVICE_VFS_write
	je	.vfs_write	; tak

	; brak obsługi podprocedury
	jmp	kernel_service.error

;-------------------------------------------------------------------------------
; wejście:
;	rcx - rozmiar ścieżki w Bajtach
;	rdx - ilość danych w Bajtach
;	rsi - wskaźnik do ciągu reprezentującego ścieżkę
;	rdi - wskaźnik do danych
.vfs_write:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdx
	push	rdi

	; zmienna lokalna
	push	STATIC_FALSE

	xchg	bx,bx


	; rozwiąż ścieżkę do pliku
	call	kernel_vfs_path_resolve
	jc	.vfs_write_end	; nie udało sie rozwiązać ścieżki do ostatniego pliku

	; odszukaj plik w katalogu docelowym
	call	kernel_vfs_file_find
	jnc	.vfs_write_ready	; nie znaleziono podanego pliku

	; utwórz pusty plik o danej nazwie
	mov	dl,	KERNEL_VFS_FILE_TYPE_regular_file
	call	kernel_vfs_file_touch
	jc	.vfs_write_end	; nie udało się utworzyć pliku

	; utworzono pusty plik
	mov	qword [rsp],	STATIC_TRUE

.vfs_write_ready:
	; zapisz dane do pliku
	mov	rcx,	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02]
	mov	rsi,	qword [rsp + STATIC_QWORD_SIZE_byte]
	call	kernel_vfs_file_write
	jnc	.vfs_write_end	; pomyślnie zapisano dane do pliku

	; utworzono pusty plik
	cmp	byte [rsp],	STATIC_FALSE
	je	.vfs_write_end	; nie

	; debug
	xchg	bx,bx

.vfs_write_end:
	; zwolnij zmienną lokalną
	add	rsp,	STATIC_QWORD_SIZE_byte

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rsi
	pop	rcx
	pop	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.vfs_write"

;-------------------------------------------------------------------------------
; wejście:
;	rcx - rozmiar ścieżki w Bajtach
;	rsi - wskaźnik do ciągu reprezentującego ścieżkę
; wyjście:
;	Flaga CF - jeśli nie udało się wczytać pliku lub nie znaleziono
;	rcx - rozmiar pliku w Bajtach
;	rdi - wskaźnik do przestrzeni z danymi pliku
.vfs_read:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi
	push	rdi
	push	rcx

	; rozwiąż ścieżkę do pliku
	call	kernel_vfs_path_resolve
	jc	.vfs_read_end	; nie udało sie rozwiązać ścieżki do ostatniego pliku

	; odszukaj plik w katalogu docelowym
	call	kernel_vfs_file_find
	jc	.vfs_read_end	; nie znaleziono podanego pliku

	; ustaw wskaźnik źródłowy na supeł pliku
	mov	rsi,	rdi

	; pobierz rozmiar pliku w Bajtach/blokach
	mov	rcx,	qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.size]

	; plik typu: zwykły plik?
	test	byte [rsi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_regular_file
	jnz	.vfs_read_regular_file	; tak

	; ilość wykorzystanej przestrzeni dla bloków danych w Bajtach
	xor	eax,	eax

	; pobierz wskaźnik pierwszego bloku danych
	mov	rcx,	qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.data]

.vfs_read_block:
	; zwiększ rozmiar katalogu w Bajtach
	add	rax,	STATIC_STRUCTURE_BLOCK.link

	; pobierz wskaźnik następnego bloku danych
	mov	rcx,	qword [rcx + STATIC_STRUCTURE_BLOCK.link]

	; koniec bloków danych?
	test	rcx,	rcx
	jnz	.vfs_read_block	; nie

	; zróć rozmiar pliku w Bajtach
	mov	rcx,	rax

.vfs_read_regular_file:
	; przygotuj przestrzeń dla ładowanego pliku w przestrzeni procesu
	call	library_page_from_size
	call	kernel_memory_alloc_task
	jc	.vfs_read_end	; brak miejsca w pamięci

	; załaduj zawartość pliku do przestrzeni pamięci procesu
	call	kernel_vfs_file_read
	jc	.vfs_read_end	; załadowano poprawnie

	; zwróć informacje o rozmiarze i wskaźniku do danych pliku
	mov	qword [rsp],	rcx
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rdi

	; koniec obsługi procedury
	jmp	.vfs_read_end

.vfs_read_end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.vfs_read"

;-------------------------------------------------------------------------------
; wejście:
;	rcx - rozmiar ścieżki w Bajtach
;	rsi - wskaźnik do ciągu reprezentującego ścieżkę
; wyjście:
;	rcx - ilość wpisów
;	rdi - wskaźnik do przestrzeni z wpisami
.vfs_dir:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rsi
	push	rdi
	push	rcx

	; rozwiąż ścieżkę do pliku
	call	kernel_vfs_path_resolve
	jc	.vfs_dir_end	; nie udało sie rozwiązać ścieżki do ostatniego pliku

	; odszukaj plik w katalogu docelowym
	call	kernel_vfs_file_find
	jc	.vfs_dir_end	; nie znaleziono podanego pliku

	; typ pliku: katalog?
	test	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_directory
	jz	.vfs_dir_not	; nie

	; pobierz ilość wpisów w katalogu i ustaw wskaźnik źródłowy na pierwszy blok danych
	mov	rsi,	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

	; oblicz rozmiar wymaganej przestrzeni dla wszystkich supłów
	mov	eax,	KERNEL_VFS_STRUCTURE_KNOT.SIZE
	mul	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.size]

	; zamień na ilość stron
	mov	rcx,	rax
	call	library_page_from_size

	; zarezerwuj przestrzeń dla procesu
	call	kernel_memory_alloc_task
	jc	.vfs_dir_end	; brak miejsca w pamięci

	; ilość wpisów przekazanych do procesu
	xor	ebx,	ebx

	; zachowaj wskaźnik do przestrzeni
	push	rdi

.vfs_dir_reload:
	; ilość wpisów na blok danych
	mov	edx,	STATIC_STRUCTURE_BLOCK.link / KERNEL_VFS_STRUCTURE_KNOT.SIZE

.vfs_dir_loop:
	; wpis zajęty?
	test	word [rsi + KERNEL_VFS_STRUCTURE_KNOT.flags],	KERNEL_VFS_FILE_FLAGS_reserved
	jz	.vfs_dir_next	; nie, sprawdź następny

	; kopiuj informacje o suple do przestrzeni procesu
	mov	ecx,	KERNEL_VFS_STRUCTURE_KNOT.SIZE
	rep	movsb

	; przekazano wpis
	inc	rbx

	; ustaw wskaźnik spowrotem na wpis
	sub	rsi,	KERNEL_VFS_STRUCTURE_KNOT.SIZE

.vfs_dir_next:
	; przesuń wskaźnik na następny wpis
	add	rsi,	KERNEL_VFS_STRUCTURE_KNOT.SIZE

	; koniec wpisów w bloku?
	dec	edx
	jnz	.vfs_dir_loop	; nie

	; załaduj następny blok danych katalogu
	and	si,	STATIC_PAGE_mask
	mov	rsi,	qword [rsi + STATIC_STRUCTURE_BLOCK.link]

	; koniec bloków danych?
	test	rsi,	rsi
	jnz	.vfs_dir_reload	; nie

	; przywróć wskaźnik do przestrzeni
	pop	rdi

	; zwróć ilość wpisów przekazanych do procesu
	mov	qword [rsp],	rbx
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rdi	; oraz wskaźnik do przestrzeni

	; koniec obsługi procedury
	jmp	.vfs_dir_end

.vfs_dir_not:
	; ustaw wskaźnik źródłowy
	mov	rsi,	rdi

	; przydziel przestrzeń pamięci o podanym rozmiarze dla procesu
	mov	rcx,	0x01	; 4 KiB dla jednego supła :/
	call	kernel_memory_alloc_task
	jc	.vfs_dir_end	; brak miejsca w pamięci

	; zachowaj wskaźnik przestrzeni danych procesu
	push	rdi

	; kopiuj informacje o suple do przestrzeni procesu
	mov	ecx,	KERNEL_VFS_STRUCTURE_KNOT.SIZE
	rep	movsb

	; przywróć wskaźnik przestrzeni danych procesu
	pop	rdi
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rdi	; zwróć do procesu

	; zwróć informacje o ilości przekazanych supłów
	mov	qword [rsp],	0x01

.vfs_dir_end:
	; przywróć oryginale rejestry
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rbx
	pop	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.vfs_dir"

;-------------------------------------------------------------------------------
; wejście:
;	rcx - ilość znaków w ścieżce do pliku
;	dl - typ pliku
;	rsi - wskaźnik do ścieżki
.vfs_touch:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi

	; rozwiąż ścieżkę do pliku
	call	kernel_vfs_path_resolve
	jc	.vfa_touch_end	; błąd, niepoprawna ścieżka

	; utwórz pusty plik
	call	kernel_vfs_file_touch

.vfa_touch_end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.vfs_touch"

;-------------------------------------------------------------------------------
; wejście:
;	rcx - ilość znaków w ciągu
;	rsi - wskaźnik do ciągu reprezentujący nazwę/ścieżkę pliku
; wyjście:
;	Flaga CF - jeśli plik nie istnieje
;	bl - typ pliku
.vfs_exist:
	; kod błędu, brak
	xor	eax,	eax

	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; rozwiąż ścieżkę do programu
	call	kernel_vfs_path_resolve
	jc	.vfs_exist_not	; błąd, niepoprawna ścieżka

	; odszukaj program w danym katalogu
	call	kernel_vfs_file_find

	; zwróć informacje o typie pliku
	mov	bl,	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type]

.vfs_exist_not:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; zwróć kod błędu
	mov	qword [rsp],	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.vfs_exist"

;===============================================================================
.system:
	; zwrócić właściwości pamięci RAM
	cmp	ax,	KERNEL_SERVICE_SYSTEM_memory
	je	.system_memory	; tak

	; zwrócić informacje o czasie?
	cmp	ax,	KERNEL_SERVICE_SYSTEM_time
	je	.system_time

	; brak obsługi podprocedury
	jmp	kernel_service.error

;-------------------------------------------------------------------------------
.system_memory:
	; rozmiar całkowity
	mov	r8,	qword [kernel_page_total_count]
	mov	r9,	qword [kernel_page_free_count]
	mov	r10,	qword [kernel_page_paged_count]

	; powrót do procesu
	jmp	kernel_service.end

	macro_debug	"kernel_service.system_memory"

;-------------------------------------------------------------------------------
.system_time:
	; zwróć uptime systemu (1 sekunda to 1024 tyknięcia)
	mov	rax,	qword [driver_rtc_microtime]
	mov	qword [rsp],	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

	macro_debug	"kernel_service.system_time"
