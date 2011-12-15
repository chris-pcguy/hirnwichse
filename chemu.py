#!/usr/bin/env python3.2
#cython: boundscheck=False
#cython: wraparound=False

import sys
import pyximport
#pyximport.install(pyimport = True)
pyximport.install()
import chemu_main



if (__name__ == '__main__'):
    try:
        chemu_class = chemu_main.ChEmu()
        chemu_class.run()
    except (SystemExit, KeyboardInterrupt):
        sys.exit(0)
    except:
        print(sys.exc_info())
        sys.exit(1)


