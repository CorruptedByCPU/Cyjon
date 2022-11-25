#!/bin/bash
#===============================================================================
#Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
#===============================================================================

radare2 -e dbg.bpinmaps=0 -d gdb://localhost:1234
