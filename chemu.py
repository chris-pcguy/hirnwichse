#!/usr/bin/env python3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=True
#cython: cdivision_warnings=True
#cython: profiling=True

from sys import exit
from pyximport import install
from traceback import print_exc
#install(pyimport = True)
install()
from chemu_main import ChEmu



if (__name__ == '__main__'):
    try:
        chemu_class = ChEmu()
        chemu_class.run()
    except (KeyboardInterrupt, SystemExit):
        exit(0)
    except:
        print_exc()
        exit(1)


