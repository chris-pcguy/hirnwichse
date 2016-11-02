
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "cpu_globals.pxi"
include "globals.pxi"

from os import stat
from os.path import join
from sys import exit
from traceback import print_exc

cdef class PortHandler:
    def __init__(self):
        self.classObject = None
        self.inPort = self.outPort = NULL

cdef class Platform:
    def __init__(self, Hirnwichse main):
        self.main = main
        self.portsIndex = 0
        for i in range(PORTS_LIST_LEN):
            self.ports[i] = NULL
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
    cdef void addReadHandlers(self, uint16_t[PORTS_LEN] portNums, object classObject, InPort inObject):
        cdef PortHandler port
        port = PortHandler()
        port.ports = portNums
        port.classObject = classObject
        port.inPort = inObject
        port.outPort = NULL
        self.ports[self.portsIndex] = <PyObject*>port
        self.portsIndex += 1
        Py_INCREF(port)
    cdef void addWriteHandlers(self, uint16_t[PORTS_LEN] portNums, object classObject, OutPort outObject):
        cdef PortHandler port
        port = PortHandler()
        port.ports = portNums
        port.classObject = classObject
        port.inPort = NULL
        port.outPort = outObject
        self.ports[self.portsIndex] = <PyObject*>port
        self.portsIndex += 1
        Py_INCREF(port)
    cdef void addReadWriteHandlers(self, uint16_t[PORTS_LEN] portNums, object classObject, InPort inObject, OutPort outObject):
        cdef PortHandler port
        port = PortHandler()
        port.ports = portNums
        port.classObject = classObject
        port.inPort = inObject
        port.outPort = outObject
        self.ports[self.portsIndex] = <PyObject*>port
        self.portsIndex += 1
        Py_INCREF(port)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil:
        cdef uint8_t i, j
        cdef uint32_t retVal, bitMask
        bitMask = BITMASKS_FF[dataSize]
        if (ioPortAddr):
            for j in range(self.portsIndex):
                if ((<PortHandler>self.ports[j]).inPort is NULL):
                    continue
                for i in range(PORTS_LEN):
                    if (not (<PortHandler>self.ports[j]).ports[i]):
                        break
                    elif ((<PortHandler>self.ports[j]).ports[i] == ioPortAddr):
                        ##self.main.debug("inPort: Port {0:#04x}. (dataSize: {1:d})", (ioPortAddr, dataSize))
                        retVal = (<PortHandler>self.ports[j]).inPort((<PortHandler>self.ports[j]).classObject, ioPortAddr, dataSize)&bitMask
                        ##self.main.debug("inPort: Port {0:#04x} returned {1:#04x}. (dataSize: {2:d})", (ioPortAddr, retVal, dataSize))
                        return retVal
        else:
            retVal = self.isadma.inPort(ioPortAddr, dataSize)&bitMask
            return retVal
        if (self.ata.isBusmaster(ioPortAddr)):
            retVal = self.ata.inPort(ioPortAddr, dataSize)&bitMask
            return retVal
        IF COMP_DEBUG:
            with gil:
                self.main.notice("inPort: Port {0:#04x} doesn't exist! (dataSize: {1:d})", (ioPortAddr, dataSize))
                self.main.notice("inPort: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", (self.main.cpu.savedEip, self.main.cpu.savedCs))
        return bitMask
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        cdef uint8_t i, j
        if (dataSize == OP_SIZE_BYTE):
            data = <uint8_t>data
        elif (dataSize == OP_SIZE_WORD):
            data = <uint16_t>data
        if (ioPortAddr):
            for j in range(self.portsIndex):
                if ((<PortHandler>self.ports[j]).outPort is NULL):
                    continue
                for i in range(PORTS_LEN):
                    if (not (<PortHandler>self.ports[j]).ports[i]):
                        break
                    elif ((<PortHandler>self.ports[j]).ports[i] == ioPortAddr):
                        ##self.main.debug("outPort: Port {0:#04x}. (data {1:#04x}; dataSize: {2:d})", (ioPortAddr, data, dataSize))
                        (<PortHandler>self.ports[j]).outPort((<PortHandler>self.ports[j]).classObject, ioPortAddr, data, dataSize)
                        return
        else:
            self.isadma.outPort(ioPortAddr, data, dataSize)
            return
        if (self.ata.isBusmaster(ioPortAddr)):
            self.ata.outPort(ioPortAddr, data, dataSize)
            return
        IF COMP_DEBUG:
            with gil:
                self.main.notice("outPort: Port {0:#04x} doesn't exist! (data: {1:#04x}; dataSize: {2:d})", (ioPortAddr, data, dataSize))
                self.main.notice("outPort: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", (self.main.cpu.savedEip, self.main.cpu.savedCs))
    cdef void fpuLowerIrq(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        self.pic.lowerIrq(FPU_IRQ)
    cdef void loadRomToMem(self, bytes romFileName, uint64_t mmAddr, uint64_t romSize):
        cdef object romFp
        cdef bytes romData
        try:
            romFp = open(romFileName, "rb")
            romData = romFp.read(romSize)
            self.main.mm.mmPhyWrite(mmAddr, romData, romSize)
        finally:
            if (romFp):
                romFp.close()
    cdef void loadRom(self, bytes romFileName, uint64_t mmAddr, uint8_t isRomOptional):
        cdef uint64_t romMemSize, romSize, size
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
            with nogil:
                mmAddr &= SIZE_1MB_MASK
                memcpy(self.main.mm.data+mmAddr, self.main.mm.romData+mmAddr, romSize)
    cdef void initMemory(self):
        cdef uint16_t i
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
        self.addReadWriteHandlers(CMOS_PORTS, self.cmos, <InPort>self.cmos.inPort, <OutPort>self.cmos.outPort)
        self.addReadWriteHandlers(PIC_PORTS, self.pic, <InPort>self.pic.inPort, <OutPort>self.pic.outPort)
        self.addReadWriteHandlers(DMA_MASTER_CONTROLLER_PORTS, self.isadma, <InPort>self.isadma.inPort, <OutPort>self.isadma.outPort)
        self.addReadWriteHandlers(DMA_SLAVE_CONTROLLER_PORTS, self.isadma, <InPort>self.isadma.inPort, <OutPort>self.isadma.outPort)
        self.addReadWriteHandlers(DMA_EXT_PAGE_REG_PORTS, self.isadma, <InPort>self.isadma.inPort, <OutPort>self.isadma.outPort)
        self.addReadWriteHandlers(PCI_CONTROLLER_PORTS, self.pci, <InPort>self.pci.inPort, <OutPort>self.pci.outPort)
        self.addReadWriteHandlers(PS2_PORTS, self.ps2, <InPort>self.ps2.inPort, <OutPort>self.ps2.outPort)
        self.addReadWriteHandlers(PIT_PORTS, self.pit, <InPort>self.pit.inPort, <OutPort>self.pit.outPort)
        self.addReadWriteHandlers(ATA1_PORTS, self.ata, <InPort>self.ata.inPort, <OutPort>self.ata.outPort)
        self.addReadWriteHandlers(ATA2_PORTS, self.ata, <InPort>self.ata.inPort, <OutPort>self.ata.outPort)
        #self.addReadWriteHandlers(ATA3_PORTS, self.ata, <InPort>self.ata.inPort, <OutPort>self.ata.outPort)
        #self.addReadWriteHandlers(ATA4_PORTS, self.ata, <InPort>self.ata.inPort, <OutPort>self.ata.outPort)
        self.addReadWriteHandlers(FDC_FIRST_PORTS, self.floppy, <InPort>self.floppy.inPort, <OutPort>self.floppy.outPort)
        #self.addReadWriteHandlers(FDC_SECOND_PORTS, self.floppy, <InPort>self.floppy.inPort, <OutPort>self.floppy.outPort)
        self.addReadWriteHandlers(PARALLEL_PORTS, self.parallel, <InPort>self.parallel.inPort, <OutPort>self.parallel.outPort)

        self.addReadHandlers(VGA_READ_PORTS, self.vga, <InPort>self.vga.inPort)
        self.addReadHandlers(SERIAL_READ_PORTS, self.serial, <InPort>self.serial.inPort)

        self.addWriteHandlers(VGA_WRITE_PORTS, self.vga, <OutPort>self.vga.outPort)
        self.addWriteHandlers(SERIAL_WRITE_PORTS, self.serial, <OutPort>self.serial.outPort)
        self.addWriteHandlers(FPU_PORTS, self, <OutPort>self.fpuLowerIrq)
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
    cdef void run(self):
        try:
            self.initMemory()
            self.initDevices()
            self.initDevicesPorts()
            self.runDevices()
        except:
            print_exc()
            exit(1)


