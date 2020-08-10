;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
kernel_service:
	; zachowaj oryginalny rejestr
	push	rax

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
	mov	qword [rsp + KERNEL_TASK_STRUCTURE_IRETQ.eflags + STATIC_QWORD_SIZE_byte],	rax

	; przywróć oryginalny rejestr
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

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

	; przesłać ciąg znaków na standardowe wyjście?
	cmp	ax,	KERNEL_SERVICE_PROCESS_out
	je	.process_out	; tak

	; pobrać ciąg znaków z standardowego wejście?
	cmp	ax,	KERNEL_SERVICE_PROCESS_in
	je	.process_in	; tak

	; koniec obsługi podprocedury
	jmp	kernel_service.error

;-------------------------------------------------------------------------------
; wejście:
;	bl - zachowanie potoku procesu
;	rcx - ilość znaków w ścieżce do pliku
;	rsi - wskaźnik do ciągu znaków reprezentujących ścieżkę do pliku
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
	call	kernel_exec

	; zwróć identyfikator uruchomionego procesu
	mov	qword [rsp],	rcx

	; utwórz potok wejścia procesu
	call	kernel_stream
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.in],	rsi

	; przygotuj potok wyjścia procesu
	call	kernel_stream

	; przekierować wyjście dziecka na wejście rodzica?
	test	bl,	KERNEL_SERVICE_PROCESS_RUN_FLAG_out_to_in_parent
	jz	.no_out_to_in_parent	; nie

	; zwolnij przygotowany potok
	call	kernel_stream_release

	; zachowaj wskaźnik struktury procesu
	push	rdi

	; pobierz identyfikator potoku wejścia rodzica
	call	kernel_task_active
	mov	rsi,	qword [rdi + KERNEL_TASK_STRUCTURE.in]

	; przywróć wskaźnik struktury procesu
	pop	rdi

.no_out_to_in_parent:
	; załaduj identyfikator potoku na wyjście procesu
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.out],	rsi

	; oznacz proces jako gotowy do przetwarzania
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active

.process_run_end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rdi
	pop	rsi

	; zwróć kod błędu
	mov	qword [rsp],	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

;-------------------------------------------------------------------------------
.process_check:
	; odszukaj proces w kolejce zadań
	call	kernel_task_pid_check

	; koniec obsługi opcji
	jmp	kernel_service.end

;-------------------------------------------------------------------------------
; wejście:
;	rcx - rozmiar przestrzeni do zaalokowania
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

	; zarezerwuj podany rozmiar przestrzeni
	call	kernel_service_memory_alloc
	jc	.process_memory_alloc_error	; brak wystarczającej ilości pamięci

	; mapuj przestrzeń
	mov	rax,	rdi
	sub	rax,	qword [kernel_memory_high_mask]	; zamień na adres bezpośredni
	mov	bx,	kernel_page_FLAG_write | kernel_page_FLAG_user | kernel_page_FLAG_available
	mov	r11,	cr3
	call	kernel_page_map_logical
	jnc	.process_memory_alloc_ready	; przydzielono

	; brak wolnej przestrzeni RAM, wyrejestruj przestrzeń procesu
	call	kernel_service_memory_release

.process_memory_alloc_error:
	; flaga, błąd
	stc

	; kod błędu
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	KERNEL_ERROR_memory_low

	; koniec obsługi przerwania
	jmp	.process_memory_alloc_end

.process_memory_alloc_ready:
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

;-------------------------------------------------------------------------------
; wejście:
;	rcx - rozmiar ciągu w Bajtach
;	rsi - wskaźnik do ciągu znaków
.process_out:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdi

	; brak ciągu dla potoku?
	test	rcx,	rcx
	jz	.process_out_end	 ; tak

	; pobierz identyfikator potoku wyjścia procesu
	call	kernel_task_active
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.out]

	; wyślij ciąg znaków na standardowe wyjście
	call	kernel_stream_out

.process_out_end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rbx

	; koniec obsługi opcji
	jmp	kernel_service.end

;-------------------------------------------------------------------------------
; wejście:
;	rdi - wskaźnik do przestrzeni bufora
; wyjście:
;	rcx - ilość przesłanych danych
.process_in:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdi

	; pobierz identyfikator potoku wejścia procesu
	call	kernel_task_active
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.in]

	; wyślij ciąg znaków na standardowe wyjście
	pop	rdi	; przywróć adres docelowy bufora procesu
	call	kernel_stream_in

	; przywróć oryginalny rejestr
	pop	rbx

	; koniec obsługi opcji
	jmp	kernel_service.end

;===============================================================================
.vfs:
	; sprawdzić poprawność ścieżki?
	cmp	ax,	KERNEL_SERVICE_VFS_exist
	jne	kernel_service.error	; plik nie istnieje

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

.vfs_exist_not:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; zwróć kod błędu
	mov	qword [rsp],	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

;===============================================================================
.system:
	; zwrócić właściwości pamięci RAM
	cmp	ax,	KERNEL_SERVICE_SYSTEM_memory
	jne	kernel_service.error	; nie

	; rozmiar całkowity
	mov	r8,	qword [kernel_page_total_count]
	mov	r9,	qword [kernel_page_free_count]
	mov	r10,	qword [kernel_page_paged_count]

	; powrót do procesu
	jmp	kernel_service.end

;===============================================================================
; wejście:
;	rcx - rozmiar przestrzeni w stronach
; wyjście:
;	Flaga CF, jeśli brak dostępnej
;	rax - kod błędu, jeśli Flaga CF jest podniesiona
;	rdi - wskaźnik do przydzielonej przestrzeni
kernel_service_memory_alloc:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdx
	push	rsi
	push	rdi
	push	rax
	push	rcx

	; zresetuj numer pierwszego bitu poszukiwanej przestrzeni
	mov	rax,	STATIC_MAX_unsigned

	; pobierz wskaźnik do właściwości procesu
	call	kernel_task_active

	; pobierz ilość opisanych stron w binarnej mapie pamięci
	mov	rcx,	qword [rdi + KERNEL_TASK_STRUCTURE.map_size]

	; przeszukaj binarną mapę pamięci procesu od początku
	mov	rsi,	qword [rdi + KERNEL_TASK_STRUCTURE.map]

.reload:
	; ilość stron wchodzących w skład rozpatrywanej przestrzeni
	xor	edx,	edx

.search:
	; sprawdź następną stronę
	inc	rax

	; koniec binarnej mapy pamięci?
	cmp	rax,	rcx
	je	.error	; tak

	; znaleziono wolną stronę?
	bt	qword [rsi],	rax
	jnc	.search	; nie

	; zachowaj numer pierwszego bitu wchodzącego w skład poszukiwanej przestrzeni
	mov	rbx,	rax

.check:
	; sprawdź następną stronę
	inc	rax

	; zalicz aktualną stronę do poszukiwanej przestrzeni
	inc	rdx

	; znaleziono całkowity rozmiar przestrzeni
	cmp	rdx,	qword [rsp]
	je	.found	; tak

	; koniec binarnej mapy pamięci?
	cmp	rax,	rcx
	je	.error	; tak

	; następna strona wchodząca w skład poszukiwanej przestrzeni?
	bt	qword [rsi],	rax
	jc	.check	; tak

	; rozpatrywana przestrzeń jest niepełna, znajdź następną
	jmp	.reload

.error:
	; zwróć kod błędu
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	KERNEL_ERROR_memory_low

	; flaga, błąd
	stc

	; koniec procedury
	jmp	.end

.found:
	; ustaw numer pierwszej strony przestrzeni do zablokowania
	mov	rax,	rbx

.lock:
	; zwolnij kolejne strony wchodzące w skład znalezionej przestrzeni
	btr	qword [rsi],	rax

	; następna strona
	inc	rax

	; koniec przetwarzania przestrzeni?
	dec	rdx
	jnz	.lock	; nie, kontynuuj

	; przelicz numer pierwszej strony przestrzeni na adres WZGLĘDNY
	shl	rbx,	STATIC_MULTIPLE_BY_PAGE_shift

	; koryguj o adres początku opisanej przestrzeni przez binarną mapę pamięci procesu
	add	rbx,	qword [kernel_memory_real_address]

	; zwróć adres do procesu
	mov	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02],	rbx

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rax
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"kernel_service_memory_alloc"

;===============================================================================
; wejście:
;	rcx - rozmiar przestrzeni w stronach
;	rdi - adres przestrzeni do zwolnienia
kernel_service_memory_release:
	; zachowaj oryginalne rejestry i flagi
	push	rax
	push	rdx
	push	rsi
	push	rdi
	push	rcx

	; pobierz wskaźnik do właściwości procesu
	call	kernel_task_active

	; pobierz wskaźnik do binarnej mapy pamięci procesu
	mov	rsi,	qword [rdi + KERNEL_TASK_STRUCTURE.map]

	; przelicz adres strony na numer bitu
	mov	rax,	rdi
	sub	rax,	qword [kernel_memory_real_address]
	shr	rax,	STATIC_PAGE_SIZE_shift

	; oblicz prdesunięcie względem początku binarnej mapy pamięci
	mov	rcx,	64
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx

	; przesuń wskaźnik na "pakiet"
	shl	rax,	STATIC_MULTIPLE_BY_8_shift
	add	rsi,	rax

	; zwolnij wszystkie strony wchodzące w skład przestrzeni
	mov	rcx,	qword [rsp]

.loop:
	; włącz bit odpowiadający za zwalnianą stronę
	bts	qword [rsi],	rdx

	; następna strona przestrzeni
	inc	rdx

	; koniec przestrzeni?
	dec	rcx
	jnz	.loop	; nie

	; przywróć oryginalne rejestry i flagi
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_service_memory_release"
