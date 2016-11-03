
include "globals.pxi"

from libc.stdint cimport *
from libc.time cimport time as ttime

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
    cdef Segment *segmentOverridePrefix
    cdef uint8_t asyncEvent, opcode, cpuHalted, debugHalt, debugSingleStep, INTR, HRQ, repPrefix, codeSegSize, operSize, addrSize
    cdef uint16_t savedCs, savedSs
    cdef uint32_t savedEip, savedEsp
    cdef uint64_t cycles, lasttime
    cdef inline void reset(self)
    cdef inline void setINTR(self, uint8_t state) nogil:
        self.INTR = state
        if (state):
            self.asyncEvent = True
            self.cpuHalted = False
    cdef inline void setHRQ(self, uint8_t state) nogil:
        self.HRQ = state
        if (state):
            self.asyncEvent = True
    #cdef inline void saveCurrentInstPointer(self) nogil
    cdef void handleAsyncEvent(self)
    cdef int exception(self, uint8_t exceptionId, int32_t errorCode=?) except BITMASK_BYTE_CONST
    cdef int handleException(self, object exception) except BITMASK_BYTE_CONST
    cdef void cpuDump(self) nogil
    cdef int doInfiniteCycles(self) except BITMASK_BYTE_CONST
    cdef int run(self, uint8_t infiniteCycles) except BITMASK_BYTE_CONST


