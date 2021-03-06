
include "globals.pxi"

from libc.stdint cimport *
from cpython.ref cimport PyObject, Py_INCREF

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

ctypedef uint32_t (*InPort)(self, uint16_t, uint8_t)
ctypedef void (*OutPort)(self, uint16_t, uint32_t, uint8_t)

cdef class PortHandler:
    cdef uint16_t[PORTS_LEN] ports
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
    cdef PyObject *ports[PORTS_LIST_LEN]
    cdef uint8_t portsIndex
    cdef void initDevices(self)
    cdef void resetDevices(self) nogil
    cdef void addReadHandlers(self, uint16_t[PORTS_LEN] portNums, object classObject, InPort inObject)
    cdef void addWriteHandlers(self, uint16_t[PORTS_LEN] portNums, object classObject, OutPort outObject)
    cdef void addReadWriteHandlers(self, uint16_t[PORTS_LEN] portNums, object classObject, InPort inObject, OutPort outObject)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void fpuLowerIrq(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void loadRomToMem(self, bytes romFileName, uint64_t mmAddr, uint64_t romSize)
    cdef void loadRom(self, bytes romFileName, uint64_t mmAddr, uint8_t isRomOptional)
    cdef void initMemory(self)
    cdef void initDevicesPorts(self)
    cdef void runDevices(self)
    cdef void run(self)


