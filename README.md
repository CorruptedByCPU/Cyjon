# Info

I'm in the process of transferring the entire operating system code to the C language, so the development speed of Cyjon will slow down a bit :)

# Cyjon (workname)

A simple, clean, multi-tasking operating system written in pure assembly language for 64-bit processors from the AMD64 family. Only ~64 KiB of size :)

![screenshot](https://github.com/CorruptedByCPU/Cyjon/blob/old/preview.png)

If possible, please run Qemu on GNU/Linux - performance against MS/Windows is overwhelming ;)

Right-clicking on the desktop will open the Menu.
To move the window around the screen, hold down the left ALT key.

### Software:

  - Qemu 5.0.0 or Bochs 2.6.11 (no SMP support on MS/Windows)
  - Nasm 2.15.1
  - Atom (with package https://atom.io/packages/language-assembly) or your own IDE ;)

### Requirements:

  - 32 MiB of RAM (for Full HD resolution)
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
