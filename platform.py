
import os

import cmos, isadma, pic, pit, ps2, vga, floppy

SIZE_64KB = 65536
SIZE_128KB = 131072
SIZE_256KB = 262144
SIZE_512KB = 524288
SIZE_1024KB = 1048576
SIZE_2048KB = 2097152
SIZE_4096KB = 4194304
ROM_SIZES = (SIZE_64KB, SIZE_128KB, SIZE_256KB, SIZE_512KB, SIZE_1024KB, SIZE_2048KB, SIZE_4096KB)

class Platform:
    def __init__(self, main):
        self.main = main
        self.readHandlers  = {}
        self.writeHandlers = {}
        self.cmos    = cmos.Cmos(self.main)
        self.isadma  = isadma.ISADma(self.main)
        self.pic     = pic.Pic(self.main)
        self.pit     = pit.Pit(self.main)
        self.ps2     = ps2.PS2(self.main)
        self.vga     = vga.Vga(self.main)
        self.floppy  = floppy.Floppy(self.main)
        
    def addHandlers(self, portNums, portHandler):
        self.addReadHandlers (portNums, portHandler)
        self.addWriteHandlers(portNums, portHandler)
    def addReadHandlers(self, portNums, portHandler):
        for portNum in portNums:
            self.readHandlers[portNum] = portHandler
    def addWriteHandlers(self, portNums, portHandler):
        for portNum in portNums:
            self.writeHandlers[portNum] = portHandler
    def delHandlers(self, portNums):
        self.delReadHandlers (portNums)
        self.delWriteHandlers(portNums)
    def delReadHandlers(self, portNums):
        for portNum in portNums:
            del self.readHandlers[portNum]
    def delWriteHandlers(self, portNums):
        for portNum in portNums:
            del self.writeHandlers[portNum]
    def inPort(self, portNum, dataSize):
        if (not portNum in self.readHandlers):
            self.main.printMsg("inPort: Port {0:#04x} doesn't exist! (dataSize: {1:d})", portNum, dataSize)
            return 0
        return self.readHandlers[portNum](portNum, dataSize)
    def outPort(self, portNum, data, dataSize):
        if (not portNum in self.writeHandlers):
            self.main.printMsg("outPort: Port {0:#04x} doesn't exist! (dataSize: {1:d})", portNum, dataSize)
            return
        self.writeHandlers[portNum](portNum, data, dataSize)
    def loadRomToMem(self, romFileName, mmAddr, romSize):
        try:
            #if (romSize not in ROM_SIZES):
            #    self.main.exitError("romSize {0:d} is NOT OK.".format(romSize))
            #    return False
            romFp = open(romFileName, "rb")
            romData = romFp.read(romSize)
            self.main.mm.mmPhyWrite(mmAddr, romData, romSize)
        finally:
            if (romFp):
                romFp.close()
    def loadRom(self, romFileName, mmAddr, isRomOptional):
        romMemSize = SIZE_64KB
        romSize = os.stat(romFileName).st_size
        
        if (not isRomOptional):
            if (romSize <= SIZE_64KB):
                romMemSize = SIZE_64KB
                mmAddr = 0xf0000
            elif (romSize <= SIZE_128KB):
                romMemSize = SIZE_128KB
                mmAddr = 0xe0000
            elif (romSize <= SIZE_256KB):
                romMemSize = SIZE_256KB
                mmAddr = 0xc0000
            elif (romSize <= SIZE_512KB):
                romMemSize = SIZE_512KB
                mmAddr = 0x80000
            else:
                if (romSize <= SIZE_1024KB):
                    romMemSize = SIZE_1024KB
                elif (romSize <= SIZE_2048KB):
                    romMemSize = SIZE_2048KB
                elif (romSize <= SIZE_4096KB):
                    romMemSize = SIZE_4096KB
                mmAddr = 0x00000
                #self.main.exitError("romMemSize {0:d} is NOT SUPPORTED!".format(romMemSize))
                #return False
        
        self.loadRomToMem(romFileName, mmAddr, romSize)
    def run(self, memSize):
        self.main.mm.mmAddArea(0, memSize)
        self.loadRom(os.path.join(self.main.romPath, self.main.biosName), 0xf0000, False)
        self.loadRom(os.path.join(self.main.romPath, self.main.vgaBiosName), 0xc0000, True)
        self.runDevices()
    def runDevices(self):
        self.cmos.run()
        self.isadma.run()
        self.pic.run()
        self.pit.run()
        self.vga.run()
        self.floppy.run()
        self.ps2.run()
        



