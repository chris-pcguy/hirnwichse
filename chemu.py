#!/usr/bin/env python3.2

import sys, argparse, threading, time, atexit

import platform, mm, cpu, misc


class ChEmu:
    def __init__(self):
        self.parser = argparse.ArgumentParser(description='ChEmu: a x86 emulator in python.')
        self.parser.add_argument('--biosname', dest='biosName', action='store', type=str, default='bios.bin', help='bios filename')
        self.parser.add_argument('--vgabiosname', dest='vgaBiosName', action='store', type=str, default='vgabios.bin', help='vgabios filename')
        self.parser.add_argument('-L', dest='romPath', action='store', type=str, default='./bios', help='romPath')
        self.parser.add_argument('-x', dest='exitIfCpuHalted', action='store_true', default=False, help='Exit if CPU if halted')
        self.parser.add_argument('--debug', dest='debugEnabled', action='store_true', default=False, help='Debug.')
        #self.parser.add_argument('--memory-save', dest='memToFile', nargs=3, type=int, action='append', help='Save Memory-Ranges to files after exit.')
        self.parser.add_argument('--testmode', dest='testModeEnabled', action='store_true', default=False, help='Enable Testmode. (Write 1. KB RAM to file)')
        self.parser.add_argument('--testmodePrefix', dest='testModePrefix', action='store', type=str, default='', help='testmodePrefix')
        self.parser.add_argument('--testmodeSuffix', dest='testModeSuffix', action='store', type=str, default=str(int(time.time())), help='testmodeSuffix')
        self.cmdArgs = self.parser.parse_args(sys.argv[1:])
        
        #print(repr(self.cmdArgs.memToFile))
        self.exitIfCpuHalted = self.cmdArgs.exitIfCpuHalted
        self.debugEnabled = self.cmdArgs.debugEnabled
        self.testModeEnabled = self.cmdArgs.testModeEnabled
        self.testModePrefix = self.cmdArgs.testModePrefix
        self.testModeSuffix = self.cmdArgs.testModeSuffix
        self.romPath = self.cmdArgs.romPath # default: './bios'
        self.biosName = self.cmdArgs.biosName # filename, default: 'bios.bin'
        self.vgaBiosName = self.cmdArgs.vgaBiosName # filename, default: 'vgabios.bin'
        self.memSize = 33554432 # 32MB
        #self.memSize = 67108864 # 64MB
        if (self.testModeEnabled):
            atexit.register(self.saveMemToFile, addr=0, size=1024, prefix=self.testModePrefix, suffix=self.testModeSuffix) # Addr: 0; Size: 1KB; 1.(first) KB.
    def exitError(self, errorStr, *errorStrArguments, errorExitCode=1):
        self.printMsg("ERROR: {0:s}".format(errorStr), *errorStrArguments)
        sys.exit(errorExitCode)
    def debug(self, debugStr, *debugStrArguments):
        if (self.debugEnabled):
            self.printMsg(debugStr, *debugStrArguments)
    def printMsg(self, msgStr, *msgStrArguments):
        print(msgStr.format(*msgStrArguments))
    def saveMemToFile(self, addr, size, prefix="", suffix=""):
        if (hasattr(self, 'mm')):
            if (prefix):
                prefix = "{prefix:s}.".format(prefix=prefix)
            if (suffix):
                suffix = ".{suffix:s}".format(suffix=suffix)
            filefp=open("{prefix:s}memdump{suffix:s}".format(prefix=prefix, suffix=suffix), "wb")
            filefp.write(self.mm.mmPhyRead(addr, size))
            filefp.close()
    def run(self):
        self.misc = misc.Misc(self)
        self.platform = platform.Platform(self)
        self.mm = mm.Mm(self)
        self.cpu = cpu.Cpu(self)
        
        self.platform.run(self.memSize)
        threading.Thread(target=self.cpu.run, name='cpu-0').start()
        while (threading.active_count() > 1):
            time.sleep(1)





if (__name__=='__main__'):
    chemu = ChEmu()
    chemu.run()



