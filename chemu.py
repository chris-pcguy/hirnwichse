#!/usr/bin/env python3.2

import sys, argparse, threading

import platform, mm, cpu, time, misc


class ChEmu:
    def __init__(self):
        self.parser = argparse.ArgumentParser(description='ChEmu: a x86 emulator in python.')
        self.debugEnabled = True
        self.romPath = './bios'
        self.memSize = 33554432 # 32MB
        #self.memSize = 67108864 # 64MB
    def exitError(self, errorStr, *errorStrArguments, errorExitCode=1):
        self.printMsg(errorStr, *errorStrArguments)
        sys.exit(errorExitCode)
    def debug(self, debugStr, *debugStrArguments):
        if (self.debugEnabled):
            self.printMsg(debugStr, *debugStrArguments)
    def printMsg(self, msgStr, *msgStrArguments):
        print(msgStr.format(*msgStrArguments))
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



