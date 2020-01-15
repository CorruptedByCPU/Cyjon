;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
kernel_init_vfs:
	; przygotuj miejsce na tablice supłów
	call	kernel_memory_alloc_page
	jc	kernel_init_panic_low_memory	; brak wystarczającej ilości pamięci RAM

	; wyczyść przestrzeń i zachowa wskaźnik katalogu głównego
	call	kernel_page_drain
	mov	qword [kernel_vfs_magicknot + KERNEL_STRUCTURE_VFS_MAGICKNOT.root],	rdi

	; ustaw wskaźnik na Super Węzeł
	mov	rdi,	kernel_vfs_magicknot

	; wypełnij katalog główny podstawowymi dowiązaniami
	mov	rsi,	rdi
	call	kernel_vfs_dir_symlinks

	;-----------------------------------------------------------------------
	; utwórz strukturę katalogów
	;-----------------------------------------------------------------------
	mov	rsi,	kernel_init_vfs_directory_structure

.loop:
	; pobierz rozmiar ścieżki
	movzx	ecx,	byte [rsi]

	; koniec struktury?
	test	cl,	cl
	jz	.end	; tak

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
	jmp	.loop

.end:
