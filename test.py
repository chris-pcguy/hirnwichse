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
from hirnwichse_test import HirnwichseTest



if (__name__ == '__main__'):
    try:
        hirnwichse_class = HirnwichseTest()
        hirnwichse_class.run()
    except (KeyboardInterrupt, SystemExit):
        exit(0)
    except:
        print_exc()
        exit(1)


