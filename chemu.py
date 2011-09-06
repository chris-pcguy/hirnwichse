#!/usr/bin/env python3.2

import chemu_main
#import cProfile

def mainfunc():
    chemu_class = chemu_main.ChEmu()
    chemu_class.run()


if (__name__=='__main__'):
    mainfunc()
    #profile.run('mainfunc()', 'chemuprof')



