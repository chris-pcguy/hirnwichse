#!/usr/bin/env python3.4
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

import os
from sys import exit
from pyximport import install
from traceback import print_exc
#install(pyimport = True)
install()

getcwd_include = "-I"+os.getcwd()
if ("CFLAGS" in os.environ):
    os.environ["CFLAGS"] += " "+getcwd_include
else:
    os.environ["CFLAGS"] = getcwd_include

from hirnwichse_main import Hirnwichse


if (__name__ == '__main__'):
    try:
        hirnwichse_class = Hirnwichse()
        hirnwichse_class.run()
    except (KeyboardInterrupt, SystemExit):
        exit(0)
    except:
        print_exc()
        exit(1)


