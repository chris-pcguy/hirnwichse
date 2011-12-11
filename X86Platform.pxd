#cimport chemu_main
#from chemu_main cimport ChEmu

cimport cmos


cdef class Platform:
    #cpdef public ChEmu main
    cpdef public object main, isadma, ps2, pic, pit, pci, vga, floppy, serial, parallel, gdbstub, pythonBios
    cpdef public cmos.Cmos cmos
    cpdef dict readHandlers, writeHandlers
    cdef unsigned char copyRomToLowMem
    cpdef initDevices(self)
    cpdef addHandlers(self, tuple portNums, object devObject)
    cpdef addReadHandlers(self, tuple portNums, object devObject)
    cpdef addWriteHandlers(self, tuple portNums, object devObject)
    cpdef delHandlers(self, tuple portNums)
    cpdef delReadHandlers(self, tuple portNums)
    cpdef delWriteHandlers(self, tuple portNums)
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned long long data, unsigned char dataSize)
    cpdef loadRomToMem(self, bytes romFileName, unsigned long long mmAddr, unsigned long long romSize)
    cpdef loadRom(self, bytes romFileName, unsigned long long mmAddr, unsigned char isRomOptional)
    cdef run(self, unsigned long long memSize)
    cdef runDevices(self)


