# Info

I'm rewriting Cyjon to be fully compatible with Fern-Night (written in C)...

The ability to run the same compilations of programs on both systems, ignited a new flame in me :D

Previous version of Cyjon is still available at **[old](https://github.com/CorruptedByCPU/Cyjon/tree/old)** branch.

# Cyjon (workname)

A simple, clean, multi-tasking operating system written in pure assembly language for 64-bit processors from the AMD64 family.

## Hey!

Before you delve into the code try to understand one important thing.

The code I write is to be simple in construction and readable by everyone, regardless of the level of knowledge of the person knowing this language (KISS).

So the code is not optimized for speed but for readability.

### Software:

  - Qemu 5.0.0 or Bochs 2.6.11 (no SMP support on MS/Windows)
  - Nasm 2.15.1

### Requirements:

  - 64 MiB of RAM

### Compilation/Exec (GNU/Linux):

	user@hostname:~/Cyjon$ chmod +x make.sh qemu.sh
	user@hostname:~/Cyjon$ ./make.sh
	user@hostname:~/Cyjon$ ./qemu.sh
