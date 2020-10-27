;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

struc	KERNEL_INIT_STRUCTURE_VFS_FILE
	.data_pointer	resb	8
	.size		resb	8
	.length		resb	1
	.path:
	.SIZE:
endstruc

;===============================================================================
kernel_init_vfs:
	; przygotuj miejsce na tablice supłów
	call	kernel_memory_alloc_page
	jc	kernel_panic_memory

	; wyczyść przestrzeń i zachowa wskaźnik katalogu głównego
	call	kernel_page_drain
	mov	qword [kernel_vfs_magicknot + KERNEL_VFS_STRUCTURE_MAGICKNOT.root],	rdi

	; ustaw wskaźnik na Super Węzeł
	mov	rdi,	kernel_vfs_magicknot

	; wypełnij katalog główny podstawowymi dowiązaniami
	mov	rsi,	rdi
	call	kernel_vfs_dir_symlinks

	;-----------------------------------------------------------------------
	; utwórz strukturę katalogów
	;-----------------------------------------------------------------------
	mov	rsi,	kernel_init_vfs_directory_structure

.dir:
	; pobierz rozmiar ścieżki
	movzx	ecx,	byte [rsi]

	; koniec struktury?
	test	cl,	cl
	jz	.next	; tak

	; przesuń wskaźnik na ścieżkę
	inc	rsi

	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; rozwiąż ścieżkę
	call	kernel_vfs_path_resolve

	; typ pliku: katalog
	mov	dl,	KERNEL_VFS_FILE_TYPE_directory
	call	kernel_vfs_file_touch	; utwórz

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

	; przesuń wskaźnik na następny wpis
	add	rsi,	rcx

	; przetwórz następny wpis
	jmp	.dir

.next:
	;-----------------------------------------------------------------------
	; załaduj do systemu plików zestaw oprogramowania wbudowanego
	;-----------------------------------------------------------------------
	mov	rsi,	kernel_init_vfs_files

.file:
	; koniec listy plików?
	cmp	qword [rsi],	STATIC_EMPTY
	je	.end	; tak

	; zachowaj wskaźnik aktualnie przetwarzanego pliku
	push	rsi

	; utwórz "pusty" plik w systemie plików
	movzx	ecx,	byte [rsi + KERNEL_INIT_STRUCTURE_VFS_FILE.length]
	mov	dl,	KERNEL_VFS_FILE_TYPE_regular_file
	add	rsi,	KERNEL_INIT_STRUCTURE_VFS_FILE.path
	call	kernel_vfs_path_resolve
	call	kernel_vfs_file_touch

	; załaduj do utworzonego pliku, zawartość
	mov	rsi,	qword [rsp]	; pobierz wskaźnik do aktualnie przetwarzanego pliku
	mov	rcx,	qword [rsi + KERNEL_INIT_STRUCTURE_VFS_FILE.size]
	mov	rsi,	qword [rsi + KERNEL_INIT_STRUCTURE_VFS_FILE.data_pointer]
	call	kernel_vfs_file_append

	; przywróć wskaźnik do aktualnie przetwarzanego pliku
	pop	rsi

	; przesuń wskaźnik na następny wpis
	movzx	ecx,	byte [rsi + KERNEL_INIT_STRUCTURE_VFS_FILE.length]
	add	rsi,	rcx
	add	rsi,	KERNEL_INIT_STRUCTURE_VFS_FILE.SIZE

	; kontynuuj
	jmp	.file

.end:
