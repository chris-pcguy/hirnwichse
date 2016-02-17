
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"

from os import stat
from os.path import join
from sys import exit
from traceback import print_exc


DEF DMA_MASTER_CONTROLLER_PORTS = (0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,
                                      0x0d,0xe,0x0f,0x81,0x82,0x83,0x87)
DEF DMA_SLAVE_CONTROLLER_PORTS = (0x89,0x8a,0x8b,0x8f,0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,
                                      0xd0,0xd2,0xd4,0xd6,0xd8,0xda,0xdc,0xde)
DEF PARALLEL_PORTS = (0x3bc, 0x3bd, 0x3be, 0x378, 0x379, 0x37a, 0x278, 0x279, 0x27a, 0x2bc, 0x2bd, 0x2be)



cdef class PortHandler:
    def __init__(self, tuple ports):
        self.ports = ports
        self.classObject = None
        self.inPort = self.outPort = NULL



cdef class Platform:
    def __init__(self, Hirnwichse main):
        self.main = main
        self.ports  = []
    cdef void initDevices(self):
        self.cmos     = Cmos(self.main)
        self.pic      = Pic(self.main)
        self.isadma   = IsaDma(self.main)
        self.pci      = Pci(self.main)
        self.ps2      = PS2(self.main)
        self.vga      = Vga(self.main)
        self.pit      = Pit(self.main)
        self.ata      = Ata(self.main)
        self.floppy   = Floppy(self.main)
        self.parallel = Parallel(self.main)
        self.serial   = Serial(self.main)
        self.gdbstub  = GDBStub(self.main)
    cdef void resetDevices(self):
        self.cmos.reset()
        #self.pic.reset()
        #self.isadma.reset()
        #self.pci.reset()
        #self.ps2.reset()
        #self.vga.reset()
        #self.pit.reset()
        self.ata.reset()
        #self.floppy.reset()
        self.parallel.reset()
        self.serial.reset()
        #self.gdbstub.reset()
    cdef void addReadHandlers(self, tuple portNums, object classObject, InPort inObject):
        cdef PortHandler port
        cdef unsigned int i # 'i' can be longer than 65536
        for i in range(len(self.ports)):
            port = <PortHandler>self.ports[i]
            if (port is None or port.ports is None or not len(port.ports)):
                continue
            if (set(port.ports) == set(portNums)):
                port.classObject = classObject
                port.inPort = inObject
                self.ports[i] = port
                return
            elif (set(port.ports).issuperset(portNums)):
                port.ports = tuple(set(port.ports).union(portNums))
                port.classObject = classObject
                port.inPort = inObject
                self.ports[i] = port
                return
        # if here, the port isn't/ports aren't registered yet... so register it/them here.
        port = PortHandler(portNums)
        port.classObject = classObject
        port.inPort = inObject
        self.ports.append(port)
    cdef void addWriteHandlers(self, tuple portNums, object classObject, OutPort outObject):
        cdef PortHandler port
        cdef unsigned int i # 'i' can be longer than 65536
        for i in range(len(self.ports)):
            port = <PortHandler>self.ports[i]
            if (port is None or port.ports is None or not len(port.ports)):
                continue
            if (set(port.ports) == set(portNums)):
                port.classObject = classObject
                port.outPort = outObject
                self.ports[i] = port
                return
            elif (set(port.ports).issuperset(portNums)):
                port.ports = tuple(set(port.ports).union(portNums))
                port.classObject = classObject
                port.outPort = outObject
                self.ports[i] = port
                return
        # if here, the port isn't/ports aren't registered yet... so register it/them here.
        port = PortHandler(portNums)
        port.classObject = classObject
        port.outPort = outObject
        self.ports.append(port)
    cdef void delHandlers(self, tuple portNums):
        cdef PortHandler port
        cdef unsigned int i # 'i' can be longer than 65536
        for i in range(len(self.ports)):
            port = <PortHandler>self.ports[i]
            if (port is None or port.ports is None):
                continue
            if (set(port.ports) == set(portNums)):
                self.ports[i] = None
                del self.ports[i]
                return
            elif (set(port.ports).issuperset(portNums)):
                port.ports = tuple(set(port.ports).difference_update(portNums))
    cdef void delReadHandlers(self, tuple portNums):
        cdef PortHandler port
        cdef unsigned int i # 'i' can be longer than 65536
        for i in range(len(self.ports)):
            port = <PortHandler>self.ports[i]
            if (port is None or port.ports is None):
                continue
            if (set(port.ports) == set(portNums)):
                port.inPort = NULL
                if (port.outPort is NULL):
                    self.ports[i] = None
                    del self.ports[i]
                return
            elif (set(port.ports).issuperset(portNums)):
                self.main.notice("delReadHandlers: Don't know what todo here.")
                return
    cdef void delWriteHandlers(self, tuple portNums):
        cdef PortHandler port
        cdef unsigned int i # 'i' can be longer than 65536
        for i in range(len(self.ports)):
            port = <PortHandler>self.ports[i]
            if (port is None or port.ports is None):
                continue
            if (set(port.ports) == set(portNums)):
                port.outPort = NULL
                if (port.inPort is NULL):
                    self.ports[i] = None
                    del self.ports[i]
                return
            elif (set(port.ports).issuperset(portNums)):
                self.main.notice("delWriteHandlers: Don't know what todo here.")
                return
    cpdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef PortHandler port
        cdef unsigned short portNum
        cdef unsigned int retVal, bitMask
        try:
            bitMask = BITMASKS_FF[dataSize]
            for port in self.ports:
                if (port is None or port.ports is None or not len(port.ports) or port.classObject is None or port.inPort is NULL):
                    continue
                for portNum in port.ports:
                    if (portNum == ioPortAddr):
                        ##self.main.debug("inPort: Port {0:#04x}. (dataSize: {1:d})", ioPortAddr, dataSize)
                        retVal = port.inPort(port.classObject, ioPortAddr, dataSize)&bitMask
                        ##self.main.debug("inPort: Port {0:#04x} returned {1:#04x}. (dataSize: {2:d})", ioPortAddr, retVal, dataSize)
                        return retVal
            if (self.ata.isBusmaster(ioPortAddr)):
                retVal = self.ata.inPort(ioPortAddr, dataSize)&bitMask
                return retVal
            self.main.notice("inPort: Port {0:#04x} doesn't exist! (dataSize: {1:d})", ioPortAddr, dataSize)
            self.main.notice("inPort: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
            return bitMask
        except:
            print_exc()
            exit(1)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef PortHandler port
        cdef unsigned short portNum
        try:
            if (dataSize == OP_SIZE_BYTE):
                data = <unsigned char>data
            elif (dataSize == OP_SIZE_WORD):
                data = <unsigned short>data
            for port in self.ports:
                if (port is None or port.ports is None or not len(port.ports) or port.classObject is None or port.outPort is NULL):
                    continue
                for portNum in port.ports:
                    if (portNum == ioPortAddr):
                        ##self.main.debug("outPort: Port {0:#04x}. (data {1:#04x}; dataSize: {2:d})", ioPortAddr, data, dataSize)
                        port.outPort(port.classObject, ioPortAddr, data, dataSize)
                        return
            if (self.ata.isBusmaster(ioPortAddr)):
                self.ata.outPort(ioPortAddr, data, dataSize)
                return
            self.main.notice("outPort: Port {0:#04x} doesn't exist! (data: {1:#04x}; dataSize: {2:d})", ioPortAddr, data, dataSize)
            self.main.notice("outPort: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        except:
            print_exc()
            exit(1)
    cdef void loadRomToMem(self, bytes romFileName, unsigned long int mmAddr, unsigned long int romSize):
        cdef object romFp
        cdef bytes romData
        try:
            romFp = open(romFileName, "rb")
            romData = romFp.read(romSize)
            self.main.mm.mmPhyWrite(mmAddr, romData, romSize)
        finally:
            if (romFp):
                romFp.close()
    cdef void loadRom(self, bytes romFileName, unsigned long int mmAddr, unsigned char isRomOptional):
        cdef unsigned long int romMemSize, romSize, size
        romMemSize = SIZE_64KB
        romSize = stat(romFileName).st_size
        if (not isRomOptional):
            for size in ROM_SIZES:
                if (size > romSize):
                    break
                romMemSize = size
                mmAddr = SIZE_4GB-romMemSize
        self.loadRomToMem(romFileName, mmAddr, romSize)
        if (not isRomOptional):
            memcpy(self.main.mm.mmGetDataPointer(mmAddr&SIZE_1MB_MASK), self.main.mm.mmGetRomDataPointer(mmAddr&SIZE_1MB_MASK), romSize)
    cdef void initMemory(self):
        cdef unsigned short i
        if (not self.main or not self.main.mm or not self.main.memSize):
            self.main.exitError("X86Platform::initMemory: not self.main or not self.main.mm or not self.main.memSize")
            return
        self.main.mm.mmClear(VGA_ROM_BASE, BITMASK_BYTE, SIZE_1MB-VGA_ROM_BASE)
        self.loadRom(join(self.main.romPath, self.main.biosFilename), 0xffff0000, False)
        if (self.main.vgaBiosFilename):
            self.loadRom(join(self.main.romPath, self.main.vgaBiosFilename), VGA_ROM_BASE, True)
        #self.main.mm.ignoreRomWrite = True # TODO: handle shadow at mm.pyx mmPhyWrite
        self.main.mm.mmClear(VGA_MEMAREA_ADDR, BITMASK_BYTE, 0x10000)
        self.main.mm.mmClear(0xb8000, BITMASK_BYTE, 0x8000)
    cdef void initDevicesPorts(self):
        self.addReadHandlers((0x70, 0x71), self.cmos, <InPort>self.cmos.inPort)
        self.addWriteHandlers((0x70, 0x71), self.cmos, <OutPort>self.cmos.outPort)
        self.addReadHandlers((0x20, 0x21, 0xa0, 0xa1), self.pic, <InPort>self.pic.inPort)
        self.addWriteHandlers((0x20, 0x21, 0xa0, 0xa1), self.pic, <OutPort>self.pic.outPort)
        self.addReadHandlers(DMA_MASTER_CONTROLLER_PORTS, self.isadma, <InPort>self.isadma.inPort)
        self.addReadHandlers(DMA_SLAVE_CONTROLLER_PORTS, self.isadma, <InPort>self.isadma.inPort)
        self.addReadHandlers(DMA_EXT_PAGE_REG_PORTS, self.isadma, <InPort>self.isadma.inPort)
        self.addReadHandlers(PCI_CONTROLLER_PORTS, self.pci, <InPort>self.pci.inPort)
        self.addWriteHandlers(DMA_MASTER_CONTROLLER_PORTS, self.isadma, <OutPort>self.isadma.outPort)
        self.addWriteHandlers(DMA_SLAVE_CONTROLLER_PORTS, self.isadma, <OutPort>self.isadma.outPort)
        self.addWriteHandlers(DMA_EXT_PAGE_REG_PORTS, self.isadma, <OutPort>self.isadma.outPort)
        self.addWriteHandlers(PCI_CONTROLLER_PORTS, self.pci, <OutPort>self.pci.outPort)
        self.addReadHandlers(VGA_READ_PORTS, self.vga, <InPort>self.vga.inPort)
        self.addWriteHandlers(VGA_WRITE_PORTS, self.vga, <OutPort>self.vga.outPort)
        self.addReadHandlers((0x60, 0x61, 0x64, 0x92), self.ps2, <InPort>self.ps2.inPort)
        self.addReadHandlers((0x40, 0x41, 0x42, 0x43), self.pit, <InPort>self.pit.inPort)
        self.addWriteHandlers((0x60, 0x61, 0x64, 0x92), self.ps2, <OutPort>self.ps2.outPort)
        self.addWriteHandlers((0x40, 0x41, 0x42, 0x43), self.pit, <OutPort>self.pit.outPort)
        self.addReadHandlers(ATA1_PORTS, self.ata, <InPort>self.ata.inPort)
        self.addReadHandlers(ATA2_PORTS, self.ata, <InPort>self.ata.inPort)
        #self.addReadHandlers(ATA3_PORTS, self.ata, <InPort>self.ata.inPort)
        #self.addReadHandlers(ATA4_PORTS, self.ata, <InPort>self.ata.inPort)
        self.addReadHandlers(FDC_FIRST_READ_PORTS, self.floppy, <InPort>self.floppy.inPort)
        #self.addReadHandlers(FDC_SECOND_READ_PORTS, self.floppy, <InPort>self.floppy.inPort)
        self.addWriteHandlers(ATA1_PORTS, self.ata, <OutPort>self.ata.outPort)
        self.addWriteHandlers(ATA2_PORTS, self.ata, <OutPort>self.ata.outPort)
        #self.addWriteHandlers(ATA3_PORTS, self.ata, <OutPort>self.ata.outPort)
        #self.addWriteHandlers(ATA4_PORTS, self.ata, <OutPort>self.ata.outPort)
        self.addWriteHandlers(FDC_FIRST_WRITE_PORTS, self.floppy, <OutPort>self.floppy.outPort)
        #self.addWriteHandlers(FDC_SECOND_WRITE_PORTS, self.floppy, <OutPort>self.floppy.outPort)
        self.addReadHandlers(PARALLEL_PORTS, self.parallel, <InPort>self.parallel.inPort)
        self.addReadHandlers(SERIAL_PORTS, self.serial, <InPort>self.serial.inPort)
        self.addWriteHandlers(PARALLEL_PORTS, self.parallel, <OutPort>self.parallel.outPort)
        self.addWriteHandlers(SERIAL_PORTS, self.serial, <OutPort>self.serial.outPort)
    cdef void runDevices(self):
        self.cmos.run()
        self.pic.run()
        self.isadma.run()
        self.pci.run()
        self.ps2.run()
        self.vga.run()
        self.pit.run()
        self.ata.run()
        self.floppy.run()
        self.parallel.run()
        self.serial.run()
        self.gdbstub.run()
    cpdef run(self):
        try:
            self.initMemory()
            self.initDevices()
            self.initDevicesPorts()
            self.runDevices()
        except:
            print_exc()
            exit(1)


