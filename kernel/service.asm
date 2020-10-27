;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
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

;-------------------------------------------------------------------------------
; wejście:
;	bl - zachowanie strumienia procesu
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
	jc	.process_run_error	; błąd, niepoprawna ścieżka

	; odszukaj program w danym katalogu
	call	kernel_vfs_file_find
	jc	.process_run_error	; błąd, pliku nie znaleziono

	; uruchom program
	call	kernel_exec
	jc	.process_run_error	; program dodany do kolejki zadań

	; zwróć identyfikator uruchomionego procesu
	mov	qword [rsp],	rcx

	; utwórz potok wejścia procesu
	call	kernel_stream
	jc	.process_run_no_memory	; brak wystarczającej przestrzeni pamięci

	; zachowaj wskaźnik strumienia wejście procesu
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.in],	rsi

	; użyć tego samego strumienia wyjścia co rodzic?
	test	bl,	KERNEL_SERVICE_PROCESS_RUN_FLAG_copy_out_of_parent
	jz	.process_run_no_copy_out_to_parent	; nie

	; zachowaj wskaźnik struktury procesu
	push	rdi

	; pobierz identyfikator strumienia wyjścia rodzica
	call	kernel_task_active
	mov	rsi,	qword [rdi + KERNEL_TASK_STRUCTURE.out]

	; przywróć wskaźnik struktury procesu
	pop	rdi

	; strumień wyjścia został odziedziczony
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_stream_out

	; kontynuuj
	jmp	.process_run_ready

.process_run_no_memory:
	; kod błędu
	mov	eax,	KERNEL_ERROR_memory_low

.process_run_revoke:
	; oznacz proces jako zamknięty
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_closed

.process_run_error:
	; zwróć kod błędu
	mov	qword [rsp],	rax

	; koniec obsługi procedury
	jmp	.process_run_end

.process_run_no_copy_out_to_parent:
	; przygotuj strumień wyjścia procesu
	call	kernel_stream
	jc	.process_run_no_memory	; brak wystarczającej przestrzeni pamięci

	; przekierować wyjście dziecka na wejście rodzica?
	test	bl,	KERNEL_SERVICE_PROCESS_RUN_FLAG_out_to_in_parent
	jz	.process_run_ready	; nie

	; zwolnij przygotowany potok
	xchg	rsi,	rdi
	call	kernel_stream_release
	xchg	rdi,	rsi

	; zachowaj wskaźnik struktury procesu
	push	rdi

	; pobierz identyfikator strumienia wejścia rodzica
	call	kernel_task_active
	mov	rsi,	qword [rdi + KERNEL_TASK_STRUCTURE.in]

	; przywróć wskaźnik struktury procesu
	pop	rdi

	; strumień wyjścia został przekierowany
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_stream_out

.process_run_ready:
	; załaduj identyfikator strumienia na wyjście procesu
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.out],	rsi

	; oznacz proces jako gotowy do przetwarzania
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active

.process_run_end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rdi
	pop	rsi

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

	; zarezerwuj podany rozmiar przestrzeni
	call	kernel_service_memory_alloc
	jc	.process_memory_alloc_error	; brak wystarczającej ilości pamięci

	; mapuj przestrzeń
	mov	rax,	rdi
	sub	rax,	qword [kernel_memory_high_mask]	; zamień na adres bezpośredni
	mov	bx,	KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_available
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

	; pobierz identyfikator strumienia wyjścia procesu
	call	kernel_task_active
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.out]

	; wyświetl znak N razy
	mov	rdx,	rcx
	mov	ecx,	STATIC_BYTE_SIZE_byte
	mov	rsi,	rsp

.loop:
	; wyślij wartość na standardowe wyjście
	call	kernel_stream_insert

	; wysłano wszystkie kopie znaku?
	dec	rdx
	jnz	.loop	; nie

.process_stream_out_char_end:
	; przywróć oryginalne rejestry
	pop	rdx	; przywróć znak z stosu
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx

	; koniec obsługi opcji
	jmp	kernel_service.end

;===============================================================================
; wejście:
;	bl - odczyt lub zapis
;	rcx - ilość danych w Bajtach
;	rsi - wskaźnik źródłowy danych
;	lub
;	rdi - wskaźnik docelowy danych
.process_stream_meta:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; rozmiar danych większy od przestrzeni meta?
	cmp	rcx,	KERNEL_STREAM_META_SIZE_byte
	ja	.process_stream_meta_error	; tak, błąd

	; pobierz identyfikator strumienia procesu
	call	kernel_task_active

	; zapisać dane?
	test	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_set
	jz	.process_stream_meta_not_save	; nie

	; strumień wejścia?
	test	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_in
	jz	.process_stream_meta_save_out	; nie

	; strumień wejścia
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.in]

	; kontynuuj
	jmp	.process_stream_meta_save

.process_stream_meta_save_out:
	; strumień wyjścia
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.out]

.process_stream_meta_save:
	; zapisz dane do meta strumienia
	mov	rdi,	rbx
	add	rdi,	KERNEL_STREAM_STRUCTURE_ENTRY.meta
	rep	movsb

	; podnieś flagę, meta dane aktualne
	or	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_meta

	; koniec procedury
	jmp	.process_stream_meta_end

.process_stream_meta_not_save:
	; meta dane aktualne?
	test	byte [rdi + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_meta
	jnz	.process_stream_meta_error	; nie

	; strumień wejścia?
	test	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_in
	jz	.process_stream_meta_read_out	; nie

	; strumień wejścia
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.in]

	; kontynuuj
	jmp	.process_stream_meta_read

.process_stream_meta_read_out:
	; strumień wyjścia
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.out]

.process_stream_meta_read:
	; wyślij do procesu meta dane
	mov	rsi,	rbx
	add	rsi,	KERNEL_STREAM_STRUCTURE_ENTRY.meta
	mov	rdi,	qword [rsp]
	rep	movsb

	; koniec procedury
	jmp	.process_stream_meta_end

.process_stream_meta_error:
	; Flaga CF, jeśli błąd
	stc

.process_stream_meta_end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx

	; koniec obsługi opcji
	jmp	kernel_service.end

;-------------------------------------------------------------------------------
; wyjście:
;	rcx - rozmiar listy w Bajtach
;	rsi - wskaźnik do przestrzeni listy
.process_list:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; przydziel przestrzeń dla procesu
	mov	rcx,	qword [kernel_task_size_page]
	call	kernel_service_memory_alloc
	jc	.end	; brak dostępnej przestrzeni



.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; koniec obsługi opcji
	jmp	kernel_service.end

;===============================================================================
.vfs:
	; sprawdzić poprawność ścieżki?
	cmp	ax,	KERNEL_SERVICE_VFS_exist
	je	.vfs_exist	; tak

	; utworzyć pusty plik?
	cmp	ax,	KERNEL_SERVICE_VFS_touch
	je	.vfs_touch	; tak

	; brak obsługi podprocedury
	jmp	kernel_service.error

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
	jc	.vfs_touch_error	; błąd, niepoprawna ścieżka

	; utwórz pusty plik
	call	kernel_vfs_file_touch
	jnc	.vfa_touch_end

.vfs_touch_error:
	; nie udało się utworzyć pliku
	stc

.vfa_touch_end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rax

	; koniec obsługi opcji
	jmp	kernel_service.end

;-------------------------------------------------------------------------------
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

;-------------------------------------------------------------------------------
.system_time:
	; zwróć uptime systemu (1 sekunda to 1024 tyknięcia)
	mov	r8,	qword [driver_rtc_microtime]

	; koniec obsługi opcji
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

	; numer pierwszego bitu wolnej przestrzeni
	mov	rax,	STATIC_MAX_unsigned

	; pobierz wskaźnik do właściwości procesu
	call	kernel_task_active

	; proces wykonujący jest usługą?
	test	qword [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_service
	jnz	.end	; zignoruj wywołanie

	; pobierz wskaźnik i ilość stron w binarnej mapie pamięci procesu
	mov	rcx,	qword [rdi + KERNEL_TASK_STRUCTURE.map_size]
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
