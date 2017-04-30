#!/bin/sh

#HDA=win95_hda.img
HDA=ros_test_1.img
#FDA=/home/chris/Downloads/disk_images/memtest86-4.0a/memtest.bin
#FDA=/home/chris/Downloads/disk_images/hal91.img
#FDA=/home/chris/Downloads/disk_images/floppy25.fs
#CDROM1=/home/chris/Downloads/disk_images/winxp_pro_with_sp2.iso

ulimit -s unlimited

#valgrind --tool=callgrind -v --dump-instr=yes --trace-jump=yes --callgrind-out-file=callgrind.log python3.6 hirnwichse.py -L bios_bochs --hda $HDA --boot 2
valgrind --tool=callgrind -v --dump-instr=yes --trace-jump=yes --callgrind-out-file=callgrind.log python3.6 hirnwichse.py -m 512 -L bios_bochs --hda $HDA --boot 2
#valgrind --tool=callgrind --callgrind-out-file=callgrind.log python3.6 hirnwichse.py -m 512 -L bios_bochs --hda $HDA --boot 2
#valgrind --tool=callgrind -v --dump-instr=yes --trace-jump=yes --callgrind-out-file=callgrind.log python3.6 hirnwichse.py -m 512 -L bios --fda $FDA --boot 1
#valgrind --tool=callgrind -v --dump-instr=yes --trace-jump=yes --callgrind-out-file=callgrind.log python3.6 hirnwichse.py -m 512 -L bios_bochs --fda $FDA --boot 1
#valgrind --tool=callgrind -v --dump-instr=yes --trace-jump=yes --callgrind-out-file=callgrind.log python3.6 hirnwichse.py -m 4 -L bios_bochs --fda $FDA --boot 1
#valgrind --tool=callgrind -v --dump-instr=yes --trace-jump=yes --callgrind-out-file=callgrind.log python3.6 hirnwichse.py -m 512 -L bios_bochs --cdrom1 $CDROM1 --boot 3
kcachegrind callgrind.log


