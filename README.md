# Info

I'll try to rewrite Cyjon to keep it up with Fern-Night.

(old code at **[old](https://github.com/CorruptedByCPU/Cyjon/tree/old)** branch)

# Cyjon (workname)

A simple, clean, multi-tasking operating system written in pure assembly language for 64-bit processors from the AMD64 family.

## Hey!

Before you delve into the code try to understand one important thing.

The code I write is to be simple in construction and readable by everyone, regardless of the level of knowledge of the person knowing this language (KISS).

Therefore, all procedures will always keep the original registers intact, at the beginning of each of them there is information about which registers are accepted and which ones are returned.

The same applies to code formatting (columns):
  - first - there are only labels and commands not related to the code (management),
  - second - is responsible for the processor instructions,
  - third, fourth (etc.) - are the values assumed by the instruction.

Each column is separated by TAB, spaces are allowed only in the space of a given column.

On the other hand, definitions, structures, and constants follow slightly different rules, but you'll notice them in no time.

### Software:

  - Qemu 5.0.0 or Bochs 2.6.11 (no SMP support on MS/Windows)
  - Nasm 2.15.1

### Requirements:

  - 64 MiB of RAM

### Compilation/Exec (GNU/Linux):

	user@hostname:~/Cyjon$ chmod +x make.sh qemu.sh
	user@hostname:~/Cyjon$ ./make.sh
	user@hostname:~/Cyjon$ ./qemu.sh
