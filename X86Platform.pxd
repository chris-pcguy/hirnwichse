
from libc.stdint cimport *
from cpython.ref cimport PyObject

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

ctypedef uint32_t (*InPort)(self, uint16_t, uint8_t) nogil
ctypedef void (*OutPort)(self, uint16_t, uint32_t, uint8_t) nogil

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
    cdef uint32_t inPortHandler(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil
    cdef void outPortHandler(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil
    cdef void fpuLowerIrq(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil
    cdef void loadRomToMem(self, bytes romFileName, uint64_t mmAddr, uint64_t romSize)
    cdef void loadRom(self, bytes romFileName, uint64_t mmAddr, uint8_t isRomOptional)
    cdef void initMemory(self)
    cdef void initDevicesPorts(self)
    cdef void runDevices(self)
    cpdef run(self)


