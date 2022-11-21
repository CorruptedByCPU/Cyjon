# Info

I'll try to rewrite Cyjon to keep it up with Fern-Night.

(old code at **old** branch)

# Cyjon (workname)

A simple, clean, multi-tasking operating system written in pure assembly language for 64-bit processors from the AMD64 family. Only ~64 KiB of size :)

### Software:

  - Qemu 5.0.0 or Bochs 2.6.11 (no SMP support on MS/Windows)
  - Nasm 2.15.1

### Requirements:

  - 64 MiB of RAM

### Compilation/Exec (GNU/Linux):

	user@hostname:~/Cyjon$ chmod +x make.sh qemu.sh
	user@hostname:~/Cyjon$ ./make.sh
	user@hostname:~/Cyjon$ ./qemu.sh