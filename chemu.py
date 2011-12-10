#!/usr/bin/env python3.2
#cython: boundscheck=False
#cython: wraparound=False

import pyximport
#pyximport.install(pyimport = True)
pyximport.install()
import chemu_main



if (__name__ == '__main__'):
    chemu_class = chemu_main.ChEmu()
    chemu_class.run()



