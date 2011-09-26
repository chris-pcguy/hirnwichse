
#cython: boundscheck=False


import sys, argparse, threading, time, atexit, _thread

import misc, mm, X86Platform, cpu


cdef class ChEmu:
    cdef public object misc, mm, platform, cpu
    cdef object parser, cmdArgs
    cdef unsigned char debugEnabled
    cdef public unsigned char quitEmu, exitIfCpuHalted, exitCode, noUI, exitOnTripleFault
    cdef public unsigned long long memSize
    cdef public bytes romPath, biosname, vgaBiosname, fdaFilename, fdbFilename
    def __init__(self):
        self.quitEmu = False
        self.exitOnTripleFault = True
        self.exitCode = 0
        atexit.register(self.quitFunc)
        self.misc = misc.Misc(self)
        self.mm = mm.Mm(self)
        self.platform = X86Platform.Platform(self)
        self.cpu = cpu.Cpu(self)
        self.parseArgs()
    def parseArgs(self):
        self.parser = argparse.ArgumentParser(description='ChEmu: a x86 emulator in python.')
        self.parser.add_argument('--biosname', dest='biosname', action='store', type=str, default='bios.bin', help='bios filename')
        self.parser.add_argument('--vgaBiosname', dest='vgaBiosname', action='store', type=str, default='vgabios.bin', help='vgabios filename')
        self.parser.add_argument('-m', dest='memSize', action='store', type=int, default=32, help='memSize in MB')
        self.parser.add_argument('-L', dest='romPath', action='store', type=str, default='./bios', help='romPath')
        self.parser.add_argument('-x', dest='exitIfCpuHalted', action='store_true', default=False, help='Exit if CPU if halted')
        self.parser.add_argument('--debug', dest='debugEnabled', action='store_true', default=False, help='Debug.')
        self.parser.add_argument('--haltedStart', dest='haltedStart', action='store_true', default=False, help='Start with halted CPU.')
        self.parser.add_argument('--fdaFilename', dest='fdaFilename', action='store', type=str, default='floppy0.img', help='fdaFilename')
        self.parser.add_argument('--fdbFilename', dest='fdbFilename', action='store', type=str, default='floppy1.img', help='fdbFilename')
        self.parser.add_argument('--noUI', dest='noUI', action='store_true', default=False, help='Disable UI.')
        self.cmdArgs = self.parser.parse_args(sys.argv[1:])
        
        self.exitIfCpuHalted = self.cmdArgs.exitIfCpuHalted
        self.debugEnabled    = self.cmdArgs.debugEnabled
        self.cpu.cpuHalted     = self.cmdArgs.haltedStart
        self.noUI    = self.cmdArgs.noUI
        self.romPath = self.cmdArgs.romPath.encode() # default: './bios'
        self.biosname = self.cmdArgs.biosname.encode() # filename, default: 'bios.bin'
        self.vgaBiosname = self.cmdArgs.vgaBiosname.encode() # filename, default: 'vgabios.bin'
        self.fdaFilename = self.cmdArgs.fdaFilename.encode() # default: ''
        self.fdbFilename = self.cmdArgs.fdbFilename.encode() # default: ''
        self.memSize = self.cmdArgs.memSize*1024*1024
    def quitFunc(self):
        self.quitEmu = True
    def exitError(self, str errorStr, *errorStrArguments, int errorExitCode=1, int exitNow=False):
        self.exitCode = errorExitCode
        self.quitFunc()
        self.printMsg("ERROR: {0:s}".format(errorStr), *errorStrArguments)
        if (exitNow):
            sys.exit(errorExitCode)
    def debug(self, str debugStr, *debugStrArguments):
        if (self.debugEnabled):
            self.printMsg(debugStr, *debugStrArguments)
    def printMsg(self, str msgStr, *msgStrArguments):
        print(msgStr.format(*msgStrArguments))
    def run(self):
        #try:
        self.platform.run(self.memSize)
        ##self.cpu.run()
        threading.Thread(target=self.cpu.run, name='cpu-0').start()
        while (threading.active_count() > 1 and not self.quitEmu):
            if (self.quitEmu):
                break
            time.sleep(2)
        #except (SystemExit, KeyboardInterrupt):
        #    self.quitFunc()
        #    sys.exit(self.exitCode)
        #finally:
        #    self.quitFunc()
        #    sys.exit(self.exitCode)





