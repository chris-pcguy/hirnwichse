
import os

import cmos, isadma, pic, pit, pci, ps2, vga, floppy, serial, parallel, gdbstub, pythonBios


SIZE_64KB  = 0x10000
SIZE_128KB = 0x20000
SIZE_256KB = 0x40000
SIZE_512KB = 0x80000
SIZE_1MB   = 0x100000
SIZE_2MB   = 0x200000
SIZE_4MB   = 0x400000
SIZE_8MB   = 0x800000
SIZE_16MB  = 0x1000000
SIZE_32MB  = 0x2000000
SIZE_64MB  = 0x4000000
SIZE_128MB = 0x8000000
SIZE_256MB = 0x10000000
ROM_SIZES = (SIZE_64KB, SIZE_128KB, SIZE_256KB, SIZE_512KB, SIZE_1MB, SIZE_2MB, SIZE_4MB,
             SIZE_8MB, SIZE_16MB, SIZE_32MB, SIZE_64MB, SIZE_128MB, SIZE_256MB)

cdef class Platform:
    cdef public object main, cmos, isadma, ps2, pic, pit, pci, vga, floppy, serial, parallel, gdbstub, pythonBios
    cdef dict readHandlers, writeHandlers
    cdef unsigned char copyRomToLowMem
    def __init__(self, object main):
        self.main = main
        self.copyRomToLowMem = True
        self.readHandlers  = {}
        self.writeHandlers = {}
        self.cmos     = cmos.Cmos(self.main)
        self.isadma   = isadma.ISADma(self.main)
        self.ps2      = ps2.PS2(self.main)
        self.pic      = pic.Pic(self.main)
        self.pit      = pit.Pit(self.main, self.ps2)
        self.pci      = pci.Pci(self.main)
        self.vga      = vga.Vga(self.main)
        self.floppy   = floppy.Floppy(self.main)
        self.serial   = serial.Serial(self.main)
        self.parallel = parallel.Parallel(self.main)
        self.gdbstub  = gdbstub.GDBStub(self.main)
        self.pythonBios = pythonBios.PythonBios(self.main)
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
        cdef unsigned long long romMemSize = SIZE_64KB
        cdef unsigned long long romSize = os.stat(romFileName).st_size
        
        if (not isRomOptional):
            for size in ROM_SIZES:
                if (size > romSize):
                    break
                romMemSize = size
                mmAddr = 0x100000000-romMemSize
        self.loadRomToMem(romFileName, mmAddr, romSize)
        if (self.copyRomToLowMem):
            if (romMemSize > SIZE_1MB):
                self.main.exitError("X86Platform::loadRom: copyRomToLowMem active and romMemSize > SIZE_1MB, exiting...")
                return
            self.main.mm.mmPhyWrite(mmAddr&0xfffff, self.main.mm.mmPhyRead(mmAddr, romSize), romSize)
    def run(self, unsigned long long memSize):
        self.main.mm.mmAddArea(0, memSize)
        self.main.mm.mmAddArea(0xfffc0000, 0x40000, mmReadOnly=False)
        self.loadRom(os.path.join(self.main.romPath, self.main.biosname), 0xffff0000, False)
        if (self.main.vgaBiosname):
            self.loadRom(os.path.join(self.main.romPath, self.main.vgaBiosname), 0xfffc0000, True)
        self.main.mm.mmGetSingleArea(0xfffc0000, 0).mmSetReadOnly(True)
        self.runDevices()
    def runDevices(self):
        self.cmos.run()
        self.isadma.run()
        self.ps2.run()
        self.pic.run()
        self.pit.run()
        self.pci.run()
        self.vga.run()
        self.floppy.run()
        self.serial.run()
        self.parallel.run()
        self.gdbstub.run()
        self.pythonBios.run()
        



