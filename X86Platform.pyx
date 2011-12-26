
import sys, os, traceback

from misc cimport Misc


include "globals.pxi"

cdef class PortHandler:
    def __init__(self, tuple ports):
        self.ports = ports
        self.classObject = None
        self.inPort = self.outPort = NULL


cdef class Platform:
    def __init__(self, object main):
        self.main = main
        self.copyRomToLowMem = True
        self.ports  = list()
    cdef initDevices(self):
        self.cmos     = Cmos(self.main)
        self.pic      = Pic(self.main)
        self.isadma   = IsaDma(self.main)
        self.pci      = Pci(self.main)
        self.vga      = Vga(self.main)
        self.ps2      = PS2(self.main)
        self.pit      = Pit(self.main)
        self.floppy   = Floppy(self.main)
        self.floppy.initObjsToNull()
        self.parallel = Parallel(self.main)
        self.serial   = Serial(self.main)
        self.gdbstub  = GDBStub(self.main)
        self.pythonBios = PythonBios(self.main)
    cdef addReadHandlers(self, tuple portNums, object classObject, InPort inObject):
        cdef PortHandler port
        cdef unsigned long i # 'i' can be longer than 65536
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
    cdef addWriteHandlers(self, tuple portNums, object classObject, OutPort outObject):
        cdef PortHandler port
        cdef unsigned long i # 'i' can be longer than 65536
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
    cdef delHandlers(self, tuple portNums):
        cdef PortHandler port
        cdef unsigned long i # 'i' can be longer than 65536
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
    cdef delReadHandlers(self, tuple portNums):
        cdef PortHandler port
        cdef unsigned long i # 'i' can be longer than 65536
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
                self.main.printMsg("delReadHandlers: Don't know what todo here.")
                return
    cdef delWriteHandlers(self, tuple portNums):
        cdef PortHandler port
        cdef unsigned long i # 'i' can be longer than 65536
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
                self.main.printMsg("delWriteHandlers: Don't know what todo here.")
                return
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef PortHandler port
        cdef unsigned short portNum
        cdef unsigned long retVal, bitMask
        try:
            bitMask = (<Misc>self.main.misc).getBitMaskFF(dataSize)
            for port in self.ports:
                if (port is None or port.ports is None or not len(port.ports) or port.classObject is None or port.inPort is NULL):
                    continue
                for portNum in port.ports:
                    if (portNum == ioPortAddr):
                        self.main.debug("inPort: Port {0:#04x}. (dataSize: {1:d})", ioPortAddr, dataSize)
                        retVal = port.inPort(port.classObject, ioPortAddr, dataSize)&bitMask
                        self.main.debug("inPort: Port {0:#04x} returned {1:#04x}. (dataSize: {2:d})", ioPortAddr, retVal, dataSize)
                        return retVal
            self.main.printMsg("Notice: inPort: Port {0:#04x} doesn't exist! (dataSize: {1:d})", ioPortAddr, dataSize)
            return bitMask
        except:
            traceback.print_exc()
            sys.exit(1)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        cdef PortHandler port
        cdef unsigned short portNum
        cdef unsigned long bitMask
        try:
            bitMask = (<Misc>self.main.misc).getBitMaskFF(dataSize)
            data &= bitMask
            for port in self.ports:
                if (port is None or port.ports is None or not len(port.ports) or port.classObject is None or port.outPort is NULL):
                    continue
                for portNum in port.ports:
                    if (portNum == ioPortAddr):
                        self.main.debug("outPort: Port {0:#04x}. (data {1:#04x}; dataSize: {2:d})", ioPortAddr, data, dataSize)
                        port.outPort(port.classObject, ioPortAddr, data, dataSize)
                        return
            self.main.printMsg("Notice: outPort: Port {0:#04x} doesn't exist! (data: {1:#04x}; dataSize: {2:d})", ioPortAddr, data, dataSize)
        except:
            traceback.print_exc()
            sys.exit(1)
    cdef loadRomToMem(self, bytes romFileName, unsigned long long mmAddr, unsigned long long romSize):
        cdef object romFp
        cdef bytes romData
        try:
            romFp = open(romFileName, "rb")
            romData = romFp.read(romSize)
            (<Mm>self.main.mm).mmPhyWrite(mmAddr, romData, romSize)
        finally:
            if (romFp):
                romFp.close()
    cdef loadRom(self, bytes romFileName, unsigned long long mmAddr, unsigned char isRomOptional):
        cdef unsigned long long romMemSize, romSize, size
        romMemSize = SIZE_64KB
        romSize = os.stat(romFileName).st_size
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
            (<Mm>self.main.mm).mmPhyWrite(mmAddr&0xfffff, (<Mm>self.main.mm).mmPhyRead(mmAddr, romSize), romSize)
    cdef run(self, unsigned long long memSize):
        self.initDevices()
        (<Mm>self.main.mm).mmAddArea(0, memSize, False, <MmArea>MmArea)
        (<Mm>self.main.mm).mmAddArea(0xfffc0000, 0x40000, False, <MmArea>MmArea)
        self.loadRom(os.path.join(self.main.romPath, self.main.biosFilename), 0xffff0000, False)
        if (self.main.vgaBiosFilename):
            self.loadRom(os.path.join(self.main.romPath, self.main.vgaBiosFilename), 0xfffc0000, True)
        <MmArea>((<Mm>self.main.mm).mmGetSingleArea(0xfffc0000, 0)).mmSetReadOnly(True)
        self.initDevicesPorts()
        self.runDevices()
    cdef initDevicesPorts(self):
        self.addReadHandlers((0x511, 0x70, 0x71), self.cmos, <InPort>self.cmos.inPort)
        self.addWriteHandlers((0x510, 0x70, 0x71), self.cmos, <OutPort>self.cmos.outPort)
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
        self.addReadHandlers((0x3c1, 0x3c5, 0x3cc, 0x3c8, 0x3da), self.vga, <InPort>self.vga.inPort)
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
    cdef runDevices(self):
        self.cmos.run()
        self.pic.run()
        self.isadma.run()
        self.pci.run()
        self.vga.run()
        self.ps2.run()
        self.pit.run()
        self.floppy.cmos = self.cmos
        self.floppy.pic = self.pic
        self.floppy.isaDma = self.isadma
        self.floppy.run()
        self.parallel.run()
        self.serial.run()
        self.gdbstub.run()
        self.pythonBios.run()



