
include "globals.pxi"

from hirnwichse_main cimport Hirnwichse
#from misc cimport Misc
from mm cimport Mm
from pic cimport Pic
from isadma cimport IsaDma
from segments cimport Segments, Segment
from registers cimport Registers
from opcodes cimport Opcodes


cdef class Cpu:
    cdef Hirnwichse main
    cdef Registers registers
    cdef Opcodes opcodes
    cdef unsigned char asyncEvent, opcode, cpuHalted, debugHalt, debugSingleStep, INTR, HRQ
    cdef unsigned short savedCs, savedSs
    cdef unsigned int savedEip, savedEsp
    cdef unsigned long int cycles
    cdef void reset(self) nogil
    cdef inline void saveCurrentInstPointer(self) nogil
    cdef void setINTR(self, unsigned char state) nogil
    cdef void setHRQ(self, unsigned char state) nogil
    cdef void handleAsyncEvent(self)
    cdef int exception(self, unsigned char exceptionId, signed int errorCode=?) except BITMASK_BYTE_CONST
    cdef int handleException(self, object exception) except BITMASK_BYTE_CONST
    cdef unsigned char parsePrefixes(self, unsigned char opcode) nogil except? BITMASK_BYTE_CONST
    cdef void cpuDump(self)
    cdef void doInfiniteCycles(self)
    cdef void doCycle(self)
    cdef run(self, unsigned char infiniteCycles = ?)


