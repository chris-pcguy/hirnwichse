#!/usr/bin/env python3.2

#cython: boundscheck=False

import pyximport
#pyximport.install(pyimport = True)
pyximport.install()
import chemu_main
#import cProfile

def mainfunc():
    chemu_class = chemu_main.ChEmu()
    chemu_class.run()


if (__name__=='__main__'):
    mainfunc()
    #cProfile.run('mainfunc()', 'chemuprof')



