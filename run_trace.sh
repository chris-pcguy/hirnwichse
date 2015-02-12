#!/bin/sh

FDA=fda

valgrind --tool=callgrind -v --dump-instr=yes --trace-jump=yes --callgrind-out-file=callgrind.log python3 hirnwichse.py -L bios_bochs --fda $FDA
kcachegrind callgrind.log


