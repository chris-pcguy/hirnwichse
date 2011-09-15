
import os

import cmos, isadma, pic, pit, pci, ps2, vga, floppy, serial, parallel, gdbstub


SIZE_64KB = 65536
SIZE_128KB = 131072
SIZE_256KB = 262144
SIZE_512KB = 524288
SIZE_1024KB = 1048576
SIZE_2048KB = 2097152
SIZE_4096KB = 4194304
ROM_SIZES = (SIZE_64KB, SIZE_128KB, SIZE_256KB, SIZE_512KB, SIZE_1024KB, SIZE_2048KB, SIZE_4096KB)

cdef class Platform:
    cdef public object main, cmos, isadma, pic, pit, pci, ps2, vga, floppy, serial, parallel, gdbstub
    cdef dict readHandlers, writeHandlers
    def __init__(self, object main):
        self.main = main
        self.readHandlers  = {}
        self.writeHandlers = {}
        self.cmos     = cmos.Cmos(self.main)
        self.isadma   = isadma.ISADma(self.main)
        self.pic      = pic.Pic(self.main)
        self.pit      = pit.Pit(self.main)
        self.pci      = pci.Pci(self.main)
        self.ps2      = ps2.PS2(self.main)
        self.vga      = vga.Vga(self.main)
        self.floppy   = floppy.Floppy(self.main)
        self.serial   = serial.Serial(self.main)
        self.parallel = parallel.Parallel(self.main)
        self.gdbstub  = gdbstub.GDBStub(self.main)
    def addHandlers(self, tuple portNums, object portHandler):
        self.addReadHandlers (portNums, portHandler)
        self.addWriteHandlers(portNums, portHandler)
    def addReadHandlers(self, tuple portNums, object portHandler):
        for portNum in portNums:
            self.readHandlers[portNum] = portHandler
    def addWriteHandlers(self, tuple portNums, object portHandler):
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
    def inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned long long retVal
        if (not ioPortAddr in self.readHandlers):
            self.main.printMsg("Notice: inPort: Port {0:#04x} doesn't exist! (dataSize: {1:d})", ioPortAddr, dataSize)
            return 0
        self.main.debug("inPort: Port {0:#04x}. (dataSize: {1:d})", ioPortAddr, dataSize)
        retVal = self.readHandlers[ioPortAddr](ioPortAddr, dataSize)
        self.main.debug("inPort: Port {0:#04x} returned {1:#04x}. (dataSize: {2:d})", ioPortAddr, retVal, dataSize)
        return retVal
    def outPort(self, unsigned short ioPortAddr, unsigned long long data, unsigned char dataSize):
        if (not ioPortAddr in self.writeHandlers):
            self.main.printMsg("Notice: outPort: Port {0:#04x} doesn't exist! (data: {1:#04x}; dataSize: {2:d})", ioPortAddr, data, dataSize)
            return
        self.main.debug("outPort: Port {0:#04x}. (data {1:#04x}; dataSize: {2:d})", ioPortAddr, data, dataSize)
        self.writeHandlers[ioPortAddr](ioPortAddr, data, dataSize)
    def loadRomToMem(self, bytes romFileName, unsigned long long mmAddr, unsigned long long romSize):
        cdef object romFp
        cdef bytes romData
        try:
            romFp = open(romFileName, "rb")
            romData = romFp.read(romSize)
            self.main.mm.mmPhyWrite(mmAddr, romData, romSize)
        finally:
            if (romFp):
                romFp.close()
    def loadRom(self, bytes romFileName, unsigned long long mmAddr, unsigned char isRomOptional):
        romMemSize = SIZE_64KB
        cdef unsigned long long romSize = os.stat(romFileName).st_size
        
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
        
        self.loadRomToMem(romFileName, mmAddr, romSize)
    def run(self, unsigned long long memSize):
        self.main.mm.mmAddArea(0, memSize)
        self.loadRom(os.path.join(self.main.romPath, self.main.biosName), 0xf0000, False)
        self.loadRom(os.path.join(self.main.romPath, self.main.vgaBiosName), 0xc0000, True)
        self.runDevices()
    def runDevices(self):
        self.cmos.run()
        self.isadma.run()
        self.pic.run()
        self.pit.run()
        self.pci.run()
        self.ps2.run()
        self.vga.run()
        self.floppy.run()
        self.serial.run()
        self.parallel.run()
        self.gdbstub.run()
        



