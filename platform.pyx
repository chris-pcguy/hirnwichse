
import os

import cmos, isadma

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
        self.cmos = cmos.Cmos(self.main)
        self.isadma  = isadma.ISADma(self.main)
        
    def addHandlers(self, tuple portNums, portHandler):
        self.addReadHandlers (portNums, portHandler)
        self.addWriteHandlers(portNums, portHandler)
    def addReadHandlers(self, tuple portNums, portHandler):
        for portNum in portNums:
            self.readHandlers[portNum] = portHandler
    def addWriteHandlers(self, tuple portNums, portHandler):
        for portNum in portNums:
            self.writeHandlers[portNum] = portHandler
    def delHandlers(self, tuple portNums):
        self.delReadHandlers (portNums)
        self.delWriteHandlers(portNums)
    def delReadHandlers(self, tuple portNums):
        for portNum in portNums:
            del self.readHandlers[portNum]
    def delWriteHandlers(self, tuple portNums):
        for portNum in portNums:
            del self.writeHandlers[portNum]
    def inPort(self, int portNum, int dataSize):
        if (not portNum in self.readHandlers):
            self.main.printMsg("inPort: Port {0:#04x} doesn't exist! (dataSize: {1:d})", portNum, dataSize)
            return 0
        return self.readHandlers[portNum](portNum, dataSize)
    def outPort(self, int portNum, long data, int dataSize):
        if (not portNum in self.writeHandlers):
            self.main.printMsg("outPort: Port {0:#04x} doesn't exist! (dataSize: {1:d})", portNum, dataSize)
            return
        return self.writeHandlers[portNum](portNum, data, dataSize)
    def loadRomToMem(self, romFileName, long mmAddr, int romSize):
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
    def loadRom(self, romFileName, long mmAddr, int isRomOptional):
        cdef int romMemSize = SIZE_64KB
        cdef int romSize = os.stat(romFileName).st_size
        
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
        
        return self.loadRomToMem(romFileName, mmAddr, romSize)
    def run(self, int memSize):
        self.main.mm.mmAddArea(0, memSize)
        self.loadRom(os.path.join(self.main.romPath, self.main.biosName), 0xf0000, isRomOptional=False)
        self.loadRom(os.path.join(self.main.romPath, self.main.vgaBiosName), 0xc0000, isRomOptional=True)
        self.runDevices()
    def runDevices(self):
        self.cmos.run()
        self.isadma.run()
        



