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
