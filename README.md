# Info

Cyjon is fully compatible with ![Fern-Night](https://github.com/CorruptedByCPU/Fern-Night/). Any modification to either repository will be reflected in the other.

Every comment, label is now in English.

Old version of Cyjon is still available at **[old 0.1440](https://github.com/CorruptedByCPU/Cyjon/tree/old)** branch and **[eldest 0.674](https://github.com/CorruptedByCPU/Cyjon/tree/eldest)** branch.

# Cyjon v0.2164 (workname)

A simple, clean, multi-tasking operating system written in pure assembly (kernel) language for 64-bit processors from the AMD64 family.

![Cyjon 0.2128](https://blackdev.org/shot/2128.png?)

## Hey!

So the code is optimized for readability, not speed.

### Software (if you want to build and run your own ISO):

  - qemu-system-x86_64
  - nasm
  - clang
  - others (gzip, ld, xorriso, git, wget)

### Compilation/Exec (GNU/Linux):

	user@hostname ~ $ git clone https://github.com/CorruptedByCPU/fern-night
	user@hostname ~ $ git clone https://github.com/CorruptedByCPU/cyjon
	user@hostname ~ $ cd fern-night && /bin/bash make.sh
	user@hostname ~ $ cd ../cyjon && /bin/bash make.sh
	user@hostname ~ $ /bin/bash qemu.sh
