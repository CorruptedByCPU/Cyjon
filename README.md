# Cyjon (workname)

A simple, clean, multi-tasking operating system written in pure assembly language for 64-bit processors from the AMD64 family.

![screenshot](https://raw.githubusercontent.com/blackend/cyjon/master/gui.png)

If possible, please run Qemu on GNU/Linux - performance against MS/Windows is overwhelming ;)

### Software:

  - Qemu 5.0.0 or Bochs 2.6.11 (no SMP support on MS/Windows)
  - Nasm 2.15.1
  - Atom (with package https://atom.io/packages/language-assembly) or your own IDE ;)

### Requirements:

  - 16 MiB of RAM (for Full HD resolution)
  - keyboard and mouse at PS2 port

### Optional:

  - network controller Intel 82540EM (E1000)

### Compilation/Exec (GNU/Linux):

	user@hostname:~/Cyjon$ chmod +x make.sh qemu.sh
	user@hostname:~/Cyjon$ ./make.sh
	user@hostname:~/Cyjon$ ./qemu.sh

### Compilation/Exec (MS/Windows):

	C:\Cyjon> make.bat
	C:\Cyjon> qemu.bat
