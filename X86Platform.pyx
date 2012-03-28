
from os import stat
from os.path import join
from sys import exc_info, exit
from time import sleep

include "globals.pxi"


cdef tuple DMA_MASTER_CONTROLLER_PORTS = (0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,
                                      0x0d,0xe,0x0f,0x81,0x82,0x83,0x87)
cdef tuple DMA_SLAVE_CONTROLLER_PORTS = (0x89,0x8a,0x8b,0x8f,0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,
                                      0xd0,0xd2,0xd4,0xd6,0xd8,0xda,0xdc,0xde)
cdef tuple PARALLEL_PORTS = (0x3bc, 0x3bd, 0x3be, 0x378, 0x379, 0x37a, 0x278, 0x279, 0x27a, 0x2bc, 0x2bd, 0x2be)
cdef tuple SERIAL_PORTS = (0x3f8, 0x3f9, 0x3fa, 0x3fb, 0x3fc, 0x3fd, 0x3fe, 0x3ff, \
                      0x2f8, 0x2f9, 0x2fa, 0x2fb, 0x2fc, 0x2fd, 0x2fe, 0x2ff, \
                      0x3e8, 0x3e9, 0x3ea, 0x3eb, 0x3ec, 0x3ed, 0x3ee, 0x3ef, \
                      0x2e8, 0x2e9, 0x2ea, 0x2eb, 0x2ec, 0x2ed, 0x2ee, 0x2ef)



cdef class PortHandler:
    def __init__(self, tuple ports):
        self.ports = ports
        self.classObject = None
        self.inPort = self.outPort = NULL


cdef class Platform:
    def __init__(self, object main, unsigned int memSize):
        self.main = main
        self.memSize = memSize
        self.copyRomToLowMem = True
        self.ports  = list()
    cdef void initDevices(self):
        self.cmos     = Cmos(self.main)
        self.pic      = Pic(self.main)
        self.isadma   = IsaDma(self.main)
        self.pci      = Pci(self.main)
        self.ps2      = PS2(self.main)
        self.vga      = Vga(self.main)
        self.pit      = Pit(self.main)
        self.floppy   = Floppy(self.main)
        self.parallel = Parallel(self.main)
        self.serial   = Serial(self.main)
        self.gdbstub  = GDBStub(self.main)
        self.pythonBios = PythonBios(self.main)
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
            bitMask = (<Misc>self.main.misc).getBitMaskFF(dataSize)
            for port in self.ports:
                if (port is None or port.ports is None or not len(port.ports) or port.classObject is None or port.inPort is NULL):
                    continue
                for portNum in port.ports:
                    if (portNum == ioPortAddr):
                        ##self.main.debug("inPort: Port {0:#04x}. (dataSize: {1:d})", ioPortAddr, dataSize)
                        retVal = port.inPort(port.classObject, ioPortAddr, dataSize)&bitMask
                        ##self.main.debug("inPort: Port {0:#04x} returned {1:#04x}. (dataSize: {2:d})", ioPortAddr, retVal, dataSize)
                        return retVal
            self.main.notice("Notice: inPort: Port {0:#04x} doesn't exist! (dataSize: {1:d})", ioPortAddr, dataSize)
            return bitMask
        except:
            print(exc_info())
            exit(1)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef PortHandler port
        cdef unsigned short portNum
        try:
            if (dataSize == OP_SIZE_BYTE):
                data = <unsigned char>data
            elif (dataSize == OP_SIZE_WORD):
                data = <unsigned short>data
            elif (dataSize == OP_SIZE_DWORD):
                data = <unsigned int>data
            elif (dataSize == OP_SIZE_QWORD):
                data = <unsigned long int>data
            for port in self.ports:
                if (port is None or port.ports is None or not len(port.ports) or port.classObject is None or port.outPort is NULL):
                    continue
                for portNum in port.ports:
                    if (portNum == ioPortAddr):
                        ##self.main.debug("outPort: Port {0:#04x}. (data {1:#04x}; dataSize: {2:d})", ioPortAddr, data, dataSize)
                        port.outPort(port.classObject, ioPortAddr, data, dataSize)
                        return
            self.main.notice("Notice: outPort: Port {0:#04x} doesn't exist! (data: {1:#04x}; dataSize: {2:d})", ioPortAddr, data, dataSize)
        except:
            print(exc_info())
            exit(1)
    cdef void loadRomToMem(self, bytes romFileName, unsigned long int mmAddr, unsigned long int romSize):
        cdef object romFp
        cdef bytes romData
        try:
            romFp = open(romFileName, "rb")
            romData = romFp.read(romSize)
            (<Mm>self.main.mm).mmPhyWrite(mmAddr, romData, romSize)
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
                mmAddr = 0x100000000-romMemSize
        self.loadRomToMem(romFileName, mmAddr, romSize)
        if (self.copyRomToLowMem):
            if (romMemSize > SIZE_1MB):
                self.main.exitError("X86Platform::loadRom: copyRomToLowMem active and romMemSize > SIZE_1MB, exiting...")
                return
            (<Mm>self.main.mm).mmPhyCopy(mmAddr&0xfffff, mmAddr, romSize)
    cdef void systemWriteHandler(self, MmArea mmArea, unsigned int offset, char *data, unsigned int dataSize):
        ### TODO: should 0xf0000-0xfffff be read-only?
        (<Mm>self.main.mm).mmAreaWrite(mmArea, offset, data, dataSize)
        if (offset >= VGA_TEXTMODE_ADDR and offset+dataSize <= (VGA_TEXTMODE_ADDR+4000)):
            self.vga.vgaAreaWrite(mmArea, offset, data, dataSize)
    cdef void initMemory(self):
        cdef MmArea biosMmArea
        cdef unsigned int i
        (<Mm>self.main.mm).run()
        for i in range(self.memSize):
            (<Mm>self.main.mm).mmAddArea(SIZE_1MB*i, False)
        (<Mm>self.main.mm).mmAddArea(0xfff00000, False)
        self.loadRom(join(self.main.romPath, self.main.biosFilename), 0xffff0000, False)
        if (self.main.vgaBiosFilename):
            self.loadRom(join(self.main.romPath, self.main.vgaBiosFilename), 0xfffc0000, True)
        (<Mm>self.main.mm).mmSetReadOnly(0xfff00000, True)
        biosMmArea = (<Mm>self.main.mm).mmGetArea(0x0) # this would include the whole first megabyte.
        biosMmArea.writeClass = self
        biosMmArea.writeHandler = <MmAreaWriteType>self.systemWriteHandler
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
        self.addReadHandlers((0x3c0, 0x3c1, 0x3c5, 0x3cc, 0x3c7, 0x3c8, 0x3c9, 0x3da), self.vga, <InPort>self.vga.inPort)
        self.addWriteHandlers((0x3c0, 0x3c2, 0x3c4, 0x3c5, 0x3c6, 0x3c7, 0x3c8, 0x3c9, 0x3ce, \
                               0x3cf, 0x3d4, 0x3d5, 0x400, 0x401, 0x402, 0x403, 0x500, 0x504), self.vga, <OutPort>self.vga.outPort)
        self.addReadHandlers((0x60, 0x61, 0x64, 0x92), self.ps2, <InPort>self.ps2.inPort)
        self.addReadHandlers((0x40, 0x41, 0x42, 0x43), self.pit, <InPort>self.pit.inPort)
        self.addWriteHandlers((0x60, 0x61, 0x64, 0x92), self.ps2, <OutPort>self.ps2.outPort)
        self.addWriteHandlers((0x40, 0x41, 0x42, 0x43), self.pit, <OutPort>self.pit.outPort)
        self.addReadHandlers(FDC_FIRST_READ_PORTS, self.floppy, <InPort>self.floppy.inPort)
        self.addReadHandlers(FDC_SECOND_READ_PORTS, self.floppy, <InPort>self.floppy.inPort)
        self.addWriteHandlers(FDC_FIRST_WRITE_PORTS, self.floppy, <OutPort>self.floppy.outPort)
        self.addWriteHandlers(FDC_SECOND_WRITE_PORTS, self.floppy, <OutPort>self.floppy.outPort)
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
        self.floppy.run()
        self.parallel.run()
        self.serial.run()
        self.gdbstub.run()
        self.pythonBios.run()
    cpdef run(self):
        try:
            self.initMemory()
            self.initDevices()
            self.initDevicesPorts()
            self.runDevices()
        except:
            print(exc_info())
            exit(1)


