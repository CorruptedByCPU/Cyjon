# Cyjon

A simple, clean, multi-tasking operating system written in pure assembly language for 64-bit processors from the AMD64 family.

![screenshot](https://raw.githubusercontent.com/blackend/cyjon/master/gui.png)

### Software:

  - Qemu 5.0.0 or Bochs 2.6.11 (no SMP support on MS/Windows)
  - Nasm 2.15.1
  - Atom (with package https://atom.io/packages/language-assembly) or your own IDE ;)

### Requirements:

  - 8 MiB of RAM
  - keyboard and mouse at PS2 port

### Optional:

  - network controller Intel 82540EM (E1000)

### Compilation (MS Windows):

	rem select a resolution supported by the BIOS
	set WIDTH=640
	set HEIGHT=480

	nasm -f bin software/console.asm	-o build/console

	nasm -f bin kernel.asm			-o build/kernel
	FOR /F "usebackq" %%A IN ('build/kernel') DO set KERNEL_SIZE=%%~zA

	nasm -f bin zero.asm			-o build/zero		-dKERNEL_FILE_SIZE_bytes=%KERNEL_SIZE% -dSELECTED_VIDEO_WIDTH_pixel=%WIDTH% -dSELECTED_VIDEO_HEIGHT_pixel=%HEIGHT%
	FOR /F "usebackq" %%A IN ('build/zero') DO set ZERO_SIZE=%%~zA

	nasm -f bin bootsector.asm		-o build/bootsector	-dZERO_FILE_SIZE_bytes=%ZERO_SIZE%

	nasm -f bin disk.asm			-o build/disk.raw

### Exec:

	# 8 MiB RAM, 2 logical CPUs, no network, hard disk connected to IDE controller
	qemu-system-x86_64 -hda file=build/disk.raw -m 8 -smp 2 -rtc base=localtime

### My production environment.

![screenshot](https://raw.githubusercontent.com/blackend/cyjon/master/environment.png)
