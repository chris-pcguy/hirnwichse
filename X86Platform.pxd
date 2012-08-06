
from misc cimport Misc
from mm cimport Mm, MmArea, MmAreaWriteType
from cmos cimport Cmos
from isadma cimport IsaDma
from pic cimport Pic
from pit cimport Pit
from pci cimport Pci
from ps2 cimport PS2
from vga cimport Vga
from ata cimport Ata
from floppy cimport Floppy
from serial cimport Serial
from parallel cimport Parallel
from gdbstub cimport GDBStub
from pythonBios cimport PythonBios

ctypedef unsigned int (*InPort)(self, unsigned short, unsigned char)
ctypedef void (*OutPort)(self, unsigned short, unsigned int, unsigned char)


cdef class PortHandler:
    cdef tuple ports
    cdef object classObject
    cdef InPort inPort
    cdef OutPort outPort


cdef class Platform:
    cpdef object main
    cdef public IsaDma isadma
    cdef public PS2 ps2
    cdef public Pic pic
    cdef public Pit pit
    cdef public Pci pci
    cdef public Vga vga
    cdef public Ata ata
    cdef public Floppy floppy
    cdef public Serial serial
    cdef public Parallel parallel
    cdef public GDBStub gdbstub
    cdef public PythonBios pythonBios
    cdef public Cmos cmos
    cdef list ports
    cdef unsigned char copyRomToLowMem
    cdef void initDevices(self)
    cdef void resetDevices(self)
    cdef void addReadHandlers(self, tuple portNums, object classObject, InPort inObject)
    cdef void addWriteHandlers(self, tuple portNums, object classObject, OutPort outObject)
    cdef void delHandlers(self, tuple portNums)
    cdef void delReadHandlers(self, tuple portNums)
    cdef void delWriteHandlers(self, tuple portNums)
    cpdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void loadRomToMem(self, bytes romFileName, unsigned long int mmAddr, unsigned long int romSize)
    cdef void loadRom(self, bytes romFileName, unsigned long int mmAddr, unsigned char isRomOptional)
    cdef void systemWriteHandler(self, MmArea mmArea, unsigned int offset, char *data, unsigned int dataSize)
    cdef void initMemory(self)
    cdef void initDevicesPorts(self)
    cdef void runDevices(self)
    cpdef run(self)


