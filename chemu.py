#!/usr/bin/env python3.2

import sys, argparse

import platform, mm, cpu


class ChEmu:
    def __init__(self):
        self.parser = argparse.ArgumentParser(description='ChEmu: a x86 emulator in python.')
        self.romPath = './bios'
        self.memSize = 33554432 # 32MB
        #self.memSize = 67108864 # 64MB

    def run(self):
        self.platform = platform.Platform(self)
        self.mm = mm.Mm(self)
        self.cpu = cpu.Cpu(self)
        self.platform.run(self.memSize)
        self.cpu.run()





if (__name__=='__main__'):
    chemu = ChEmu()
    chemu.run()



