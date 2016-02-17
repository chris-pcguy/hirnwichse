
include "globals.pxi"

from hirnwichse_main cimport Hirnwichse
#from misc cimport Misc
from mm cimport Mm
from pic cimport Pic
from isadma cimport IsaDma
from segments cimport Segments, Segment
from registers cimport Registers
from opcodes cimport Opcodes
from cpython.ref cimport PyObject


cdef class Cpu:
    cdef Hirnwichse main
    cdef Registers registers
    cdef Opcodes opcodes
    cdef PyObject *segmentOverridePrefix
    cdef unsigned char asyncEvent, opcode, cpuHalted, debugHalt, debugSingleStep, INTR, HRQ, repPrefix, operandSizePrefix, addressSizePrefix, codeSegSize, operSize, addrSize
    cdef unsigned short savedCs, savedSs
    cdef unsigned int savedEip, savedEsp
    cdef unsigned long int cycles
    cdef inline void reset(self)
    cdef inline void resetPrefixes(self) nogil:
        self.operandSizePrefix = self.addressSizePrefix = self.repPrefix = 0
        self.segmentOverridePrefix = NULL
    cdef inline void setINTR(self, unsigned char state) nogil:
        self.INTR = state
        if (state):
            self.asyncEvent = True
            self.cpuHalted = False
    cdef inline void setHRQ(self, unsigned char state) nogil:
        self.HRQ = state
        if (state):
            self.asyncEvent = True
    cdef inline void readCodeSegSize(self) nogil:
        self.operSize = ((((self.codeSegSize==OP_SIZE_WORD)==self.operandSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
        self.addrSize = ((((self.codeSegSize==OP_SIZE_WORD)==self.addressSizePrefix) and OP_SIZE_DWORD) or OP_SIZE_WORD)
    cdef inline void saveCurrentInstPointer(self) nogil
    cdef void handleAsyncEvent(self)
    cdef int exception(self, unsigned char exceptionId, signed int errorCode=?) except BITMASK_BYTE_CONST
    cdef int handleException(self, object exception) except BITMASK_BYTE_CONST
    cdef unsigned char parsePrefixes(self, unsigned char opcode) nogil except? BITMASK_BYTE_CONST
    cdef void cpuDump(self)
    cdef void doInfiniteCycles(self)
    cdef void doCycle(self)
    cdef run(self, unsigned char infiniteCycles = ?)


