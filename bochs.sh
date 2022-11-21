#===============================================================================
#Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
#===============================================================================

# clear debug log file
echo "" > serial.log

# run with specific configration
/opt/bochs/bin/bochs -f linux.bxrc -q

# show debug log
cat serial.log
