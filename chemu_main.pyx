
#cython: boundscheck=False
#cython: wraparound=False


from sys import argv, exit, stdout
from argparse import ArgumentParser
from atexit import register
from traceback import print_exc

include "globals.pxi"



cdef class ChEmu:
    def __init__(self):
        self.quitEmu = False
        self.exitOnTripleFault = True
        register(self.quitFunc)
    cpdef parseArgs(self):
        self.parser = ArgumentParser(description='ChEmu: a x86 emulator in python.')
        self.parser.add_argument('--biosFilename', dest='biosFilename', action='store', type=str, default='bios.bin', help='bios filename')
        self.parser.add_argument('--vgaBiosFilename', dest='vgaBiosFilename', action='store', type=str, default='vgabios.bin', help='vgabios filename')
        self.parser.add_argument('-m', dest='memSize', action='store', type=int, default=64, help='memSize in MB')
        self.parser.add_argument('-L', dest='romPath', action='store', type=str, default='./bios', help='romPath')
        self.parser.add_argument('-x', dest='exitIfCpuHalted', action='store_true', default=False, help='Exit if CPU if halted')
        self.parser.add_argument('--debug', dest='debugEnabled', action='store_true', default=False, help='Debug.')
        self.parser.add_argument('--fdaFilename', dest='fdaFilename', action='store', type=str, default='floppy0.img', help='fdaFilename')
        self.parser.add_argument('--fdbFilename', dest='fdbFilename', action='store', type=str, default='floppy1.img', help='fdbFilename')
        self.parser.add_argument('--hdaFilename', dest='hdaFilename', action='store', type=str, default='hd0.img', help='hdaFilename')
        self.parser.add_argument('--hdbFilename', dest='hdbFilename', action='store', type=str, default='hd1.img', help='hdbFilename')
        self.parser.add_argument('--noUI', dest='noUI', action='store_true', default=False, help='Disable UI.')
        self.parser.add_argument('--forceFloppyDiskType', dest='forceFloppyDiskType', action='store', type=int, default=4, help='Force FloppyDiskType: 0==auto detect; 1==360K; 2==1.2M; 3==720K; 4==1.44M; 5==2.88M')
        self.cmdArgs = self.parser.parse_args(argv[1:])

        self.exitIfCpuHalted = self.cmdArgs.exitIfCpuHalted
        self.debugEnabled    = self.cmdArgs.debugEnabled
        self.noUI    = self.cmdArgs.noUI
        self.romPath = self.cmdArgs.romPath.encode() # default: './bios'
        self.biosFilename = self.cmdArgs.biosFilename.encode() # filename, default: 'bios.bin'
        self.vgaBiosFilename = self.cmdArgs.vgaBiosFilename.encode() # filename, default: 'vgabios.bin'
        self.fdaFilename = self.cmdArgs.fdaFilename.encode() # default: ''
        self.fdbFilename = self.cmdArgs.fdbFilename.encode() # default: ''
        self.hdaFilename = self.cmdArgs.hdaFilename.encode() # default: ''
        self.hdbFilename = self.cmdArgs.hdbFilename.encode() # default: ''
        self.forceFloppyDiskType    = self.cmdArgs.forceFloppyDiskType
        self.memSize = self.cmdArgs.memSize
    cpdef quitFunc(self):
        self.quitEmu = True
    def exitError(self, str msg, *msgArgs): # this needs to be 'def'
        print("ERROR: " + msg.format(*msgArgs))
        self.quitFunc()
        #exit(1)
    def debug(self, str msg, *msgArgs): # this needs to be 'def'
        if (self.debugEnabled):
            print("DEBUG: " + msg.format(*msgArgs))
    def notice(self, str msg, *msgArgs): # this needs to be 'def'
        print("NOTICE: " + msg.format(*msgArgs))
        stdout.flush()
    cpdef runThreadFunc(self):
        self.platform.run()
        (<Pic>self.platform.pic).cpuInstance = self.cpu
        (<Pic>self.platform.pic).setINTR = <SetINTR>self.cpu.setINTR
        (<IsaDma>self.platform.isadma).cpuInstance = self.cpu
        (<IsaDma>self.platform.isadma).setHRQ = <SetHRQ>self.cpu.setHRQ
        self.cpu.run()
    cpdef reset(self, unsigned char resetHardware):
        self.cpu.reset()
        if (resetHardware):
            self.platform.resetDevices()
    cpdef run(self):
        try:
            self.parseArgs()
            self.misc = Misc(self)
            self.mm = Mm(self)
            self.platform = Platform(self)
            self.cpu = Cpu(self)
            self.runThreadFunc()
        except:
            print_exc()
            exit(1)
        ###



