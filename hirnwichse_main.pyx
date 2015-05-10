
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"

from sys import argv, exit, stdout
from argparse import ArgumentParser
from atexit import register
from traceback import print_exc



cdef class Hirnwichse:
    def __init__(self):
        self.quitEmu = False
        self.exitOnTripleFault = True
        register(self.quitFunc)
    cpdef parseArgs(self):
        self.parser = ArgumentParser(description='Hirnwichse: a x86 emulator in python.')
        self.parser.add_argument('--bios', dest='biosFilename', action='store', type=str, default='bios.bin', help='bios filename')
        self.parser.add_argument('--vgabios', dest='vgaBiosFilename', action='store', type=str, default='vgabios.bin', help='vgabios filename')
        self.parser.add_argument('-m', dest='memSize', action='store', type=int, default=64, help='memSize in MB')
        self.parser.add_argument('-L', dest='romPath', action='store', type=str, default='./bios', help='romPath')
        self.parser.add_argument('-x', dest='exitIfCpuHalted', action='store_true', default=False, help='Exit if CPU if halted')
        self.parser.add_argument('--debug', dest='debugEnabled', action='store_true', default=False, help='Debug.')
        self.parser.add_argument('--debugHalt', dest='debugHalt', action='store_true', default=False, help='Start with halted CPU')
        self.parser.add_argument('--fda', dest='fdaFilename', action='store', type=str, default='floppy0.img', help='fdaFilename')
        self.parser.add_argument('--fdb', dest='fdbFilename', action='store', type=str, default='floppy1.img', help='fdbFilename')
        self.parser.add_argument('--hda', dest='hdaFilename', action='store', type=str, default='hd0.img', help='hdaFilename')
        self.parser.add_argument('--hdb', dest='hdbFilename', action='store', type=str, default='hd1.img', help='hdbFilename')
        self.parser.add_argument('--cdrom', dest='cdromFilename', action='store', type=str, default='cdrom.iso', help='cdromFilename')
        self.parser.add_argument('--boot', dest='bootFrom', action='store', type=int, default=BOOT_FROM_FD, help='bootFrom (0==none, 1==FD, 2==HD, 3==CD)')
        self.parser.add_argument('--noUI', dest='noUI', action='store_true', default=False, help='Disable UI.')
        self.parser.add_argument('--fdaType', dest='fdaType', action='store', type=int, default=4, help='fdaType: 0==auto detect; 1==360K; 2==1.2M; 3==720K; 4==1.44M; 5==2.88M')
        self.parser.add_argument('--fdbType', dest='fdbType', action='store', type=int, default=4, help='fdbType: 0==auto detect; 1==360K; 2==1.2M; 3==720K; 4==1.44M; 5==2.88M')
        self.cmdArgs = self.parser.parse_args(argv[1:])

        self.exitIfCpuHalted = self.cmdArgs.exitIfCpuHalted
        self.debugEnabled    = self.cmdArgs.debugEnabled
        self.debugHalt    = self.cmdArgs.debugHalt
        self.noUI    = self.cmdArgs.noUI
        self.romPath = self.cmdArgs.romPath.encode() # default: './bios'
        self.biosFilename = self.cmdArgs.biosFilename.encode() # filename, default: 'bios.bin'
        self.vgaBiosFilename = self.cmdArgs.vgaBiosFilename.encode() # filename, default: 'vgabios.bin'
        self.fdaFilename = self.cmdArgs.fdaFilename.encode() # default: ''
        self.fdbFilename = self.cmdArgs.fdbFilename.encode() # default: ''
        self.hdaFilename = self.cmdArgs.hdaFilename.encode() # default: ''
        self.hdbFilename = self.cmdArgs.hdbFilename.encode() # default: ''
        self.cdromFilename = self.cmdArgs.cdromFilename.encode() # default: ''
        self.bootFrom = self.cmdArgs.bootFrom # default: BOOT_FROM_FD
        self.fdaType    = self.cmdArgs.fdaType # default: 4
        self.fdbType    = self.cmdArgs.fdbType # default: 4
        self.memSize = self.cmdArgs.memSize
    cpdef quitFunc(self):
        self.quitEmu = True
    def exitError(self, str msg, *msgArgs): # this needs to be 'def'
        print("ERROR: " + msg.format(*msgArgs))
        stdout.flush()
        self.cpu.cpuDump()
        self.quitFunc()
        #exit(1)
    def debug(self, str msg, *msgArgs): # this needs to be 'def'
        if (self.debugEnabled):
            print("DEBUG: " + msg.format(*msgArgs))
    def notice(self, str msg, *msgArgs): # this needs to be 'def'
        print("NOTICE: " + msg.format(*msgArgs))
        stdout.flush()
    cpdef reset(self, unsigned char resetHardware):
        self.cpu.reset()
        if (resetHardware):
            self.platform.resetDevices()
    cpdef run(self):
        try:
            self.parseArgs()
            self.misc = Misc()
            self.mm = Mm(self)
            self.platform = Platform(self)
            self.cpu = Cpu(self)
            self.platform.run()
            self.cpu.run()
        except:
            print_exc()
            exit(1)
        ###



