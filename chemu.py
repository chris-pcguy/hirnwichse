#!/usr/bin/env python3.2
#cython: boundscheck=False
#cython: wraparound=False

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
    except (SystemExit, KeyboardInterrupt):
        exit(0)
    except:
        print(print_exc())
        exit(1)


