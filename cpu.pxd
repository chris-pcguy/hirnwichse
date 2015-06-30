
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
    cdef public Registers registers
    cdef Opcodes opcodes
    cdef public unsigned char asyncEvent, opcode, cpuHalted, debugHalt, \
      debugSingleStep
    cdef unsigned char INTR, HRQ
    cdef public unsigned short savedCs, savedSs
    cdef public unsigned int savedEip, savedEsp
    cdef public unsigned long int cycles
    cdef unsigned long int oldCycleInc
    cdef void reset(self)
    cdef inline void saveCurrentInstPointer(self)
    cdef void setINTR(self, unsigned char state)
    cdef void setHRQ(self, unsigned char state)
    cpdef handleAsyncEvent(self)
    cpdef exception(self, unsigned char exceptionId, signed int errorCode=?)
    cpdef handleException(self, object exception)
    cdef unsigned char parsePrefixes(self, unsigned char opcode) except? BITMASK_BYTE
    cpdef cpuDump(self)
    cpdef doInfiniteCycles(self)
    cpdef doCycle(self)
    cpdef run(self, unsigned char infiniteCycles = ?)


