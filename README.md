# Cyjon

A simple, clean, multi-tasking operating system written in pure assembly language for 64-bit processors from the AMD64 family.

![screenshot](https://raw.githubusercontent.com/blackend/cyjon/master/cyjon.png)
![screenshot](https://raw.githubusercontent.com/blackend/cyjon/master/debug.png)

### Requirements:

  - 2 MiB of RAM (1 MiB after 0x00100000)
  - keyboard at PS2 port

### Optional:

  - network controller Intel 82540EM (E1000)

### Compilation (GNU/Linux):

	# select a resolution supported by the BIOS
	WIDTH=640
	HEIGHT=480

	nasm -f bin software/init.asm		-o build/init
	nasm -f bin software/shell.asm		-o build/shell
	nasm -f bin software/hello.asm		-o build/hello

	nasm -f bin kernel/init/boot.asm	-o build/boot
	nasm -f bin kernel/kernel.asm		-o build/kernel \
		-dMULTIBOOT_VIDEO_WIDTH_pixel=${WIDTH} \
		-dMULTIBOOT_VIDEO_HEIGHT_pixel=${HEIGHT}
	nasm -f bin zero/zero.asm		-o build/disk.raw \
		-dMULTIBOOT_VIDEO_WIDTH_pixel=${WIDTH} \
		-dMULTIBOOT_VIDEO_HEIGHT_pixel=${HEIGHT}

### Compilation (MS Windows):

	rem select a resolution supported by the BIOS
	set WIDTH=640
	set HEIGHT=480

	nasm -f bin software/init.asm		-o build/init
	nasm -f bin software/shell.asm		-o build/shell
	nasm -f bin software/hello.asm		-o build/hello

	nasm -f bin kernel/init/boot.asm	-o build/boot
	nasm -f bin kernel/kernel.asm		-o build/kernel -dMULTIBOOT_VIDEO_WIDTH_pixel=%WIDTH% -dMULTIBOOT_VIDEO_HEIGHT_pixel=%HEIGHT%
	nasm -f bin zero/zero.asm		-o build/disk.raw -dMULTIBOOT_VIDEO_WIDTH_pixel=%WIDTH% -dMULTIBOOT_VIDEO_HEIGHT_pixel=%HEIGHT%

### Exec:

	# 2 MiB RAM, 2 logical CPUs, no network, hard disk connected to IDE controller
	qemu-system-x86_64 -hda file=build/disk.raw -m 2 -smp 2 -rtc base=localtime
