;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_bd:
	; sprawdź czy dostępny jest kontroler IDE
	mov	eax,	DRIVER_PCI_CLASS_SUBCLASS_ide
	call	driver_pci_find_class_and_subclass
	jc	.ide_end	; brak

	; inicjalizuj dostępne nośniki na kontrolerze IDE
	call	driver_ide_init

	; znaleziono jakiekolwiek nośniki danych?
	cmp	byte [driver_ide_devices_count],	STATIC_EMPTY
	je	.ide_end	; nie

	; zarejestruj wszystkie dostępne nośniki danych
	xor	cl,	cl	; zaczynając od pierwszego wpisu
	mov	rdi,	driver_ide_devices

.ide_loop:
	; wpis uzupełniony?
	cmp	word [rdi + DRIVER_IDE_STRUCTURE_DEVICE.channel],	STATIC_EMPTY
	je	.ide_next	; nie

	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; pobierz rozmiar nośnika w Bajtach
	mov	rax,	qword [rdi + DRIVER_IDE_STRUCTURE_DEVICE.blocks]
	shl	rax,	STATIC_MULTIPLE_BY_512_shift	; zamień na Bajty

	; utwórz urządzenie blokowe w wirtualnym systemie plików
	mov	ecx,	kernel_init_string_storage_ide_hd_end - kernel_init_string_storage_ide_hd_path
	mov	rsi,	kernel_init_string_storage_ide_hd_path
	call	kernel_vfs_path_resolve
	mov	rbx,	qword [rsp]
	mov	dl,	KERNEL_VFS_FILE_TYPE_block_device
	call	kernel_vfs_file_touch

	; uzupełnij metadata urządzenia blokowego
	mov	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.meta + KERNEL_VFS_STRUCTURE_META.data + KERNEL_VFS_STRUCTURE_META_BLOCK_DEVICE.entry],	driver_ide_entry_table
	mov	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.meta + KERNEL_VFS_STRUCTURE_META.data + KERNEL_VFS_STRUCTURE_META_BLOCK_DEVICE.properties],	cl

	; aktualizuj rozmiar urządzenia blokowego
	mov	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.size],	rax

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

.ide_next:
	; następna litera nośnika
	inc	byte [kernel_init_string_storage_ide_hd_letter]

	; przesuń wskaźnik na następny wpis
	add	rdi,	DRIVER_IDE_STRUCTURE_DEVICE.SIZE

	; następny wpis
	inc	cl

	; koniec tablicy?
	cmp	cl,	4
	jb	.ide_loop	; nie

.ide_end:
	; ; odszukaj kontroler AHCI na magistrali
	; mov	ax,	DRIVER_PCI_CLASS_SUBCLASS_ahci
	; call	driver_pci_find_class_and_subclass
	; jc	.end	; nie znaleziono
	;
	; ; inicjalizuj dostępne nośniki na kontrolerze AHCI
	; call	driver_ahci_init

.end:

	; debug
	jmp	$

kernel_bd_end:
