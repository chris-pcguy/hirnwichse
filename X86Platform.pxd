
from hirnwichse_main cimport Hirnwichse
from cmos cimport Cmos
from isadma cimport IsaDma
from pic cimport Pic
from pit cimport Pit
from pci cimport Pci
from ps2 cimport PS2
from vga cimport Vga
from ata cimport Ata
from floppy cimport Floppy
from serial_dev cimport Serial
from parallel cimport Parallel
from gdbstub cimport GDBStub
from libc.string cimport memcpy

ctypedef unsigned int (*InPort)(self, unsigned short, unsigned char)
ctypedef void (*OutPort)(self, unsigned short, unsigned int, unsigned char)

cdef class PortHandler:
    cdef tuple ports
    cdef object classObject
    cdef InPort inPort
    cdef OutPort outPort


cdef class Platform:
    cdef Hirnwichse main
    cdef IsaDma isadma
    cdef PS2 ps2
    cdef Pic pic
    cdef Pit pit
    cdef Pci pci
    cdef Vga vga
    cdef Ata ata
    cdef Floppy floppy
    cdef Serial serial
    cdef Parallel parallel
    cdef GDBStub gdbstub
    cdef Cmos cmos
    cdef list ports
    cdef void initDevices(self)
    cdef void resetDevices(self)
    cdef void addReadHandlers(self, tuple portNums, object classObject, InPort inObject)
    cdef void addWriteHandlers(self, tuple portNums, object classObject, OutPort outObject)
    cdef void delHandlers(self, tuple portNums)
    cdef void delReadHandlers(self, tuple portNums)
    cdef void delWriteHandlers(self, tuple portNums)
    cpdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cpdef fpuLowerIrq(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void loadRomToMem(self, bytes romFileName, unsigned long int mmAddr, unsigned long int romSize)
    cdef void loadRom(self, bytes romFileName, unsigned long int mmAddr, unsigned char isRomOptional)
    cdef void initMemory(self)
    cdef void initDevicesPorts(self)
    cdef void runDevices(self)
    cpdef run(self)


