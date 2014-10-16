#!/usr/bin/env python3.4

from sys import exit
from pyximport import install
from traceback import print_exc
#install(pyimport = True)
install()
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


