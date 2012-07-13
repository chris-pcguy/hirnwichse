
from misc cimport Misc
from mm cimport Mm
from pic cimport Pic
from isadma cimport IsaDma
from segments cimport Segments
from registers cimport Registers
from opcodes cimport Opcodes


cdef class Cpu:
    cpdef object main
    cdef public Registers registers
    cdef Opcodes opcodes
    cdef public unsigned char asyncEvent, opcode, cpuHalted, debugHalt, \
      debugSingleStep, exceptionLevel
    cdef unsigned char INTR, HRQ
    cdef public unsigned short savedCs
    cdef public unsigned int savedEip
    cdef public unsigned long int cycles
    cdef unsigned long int oldCycleInc
    cdef void reset(self)
    cdef inline void saveCurrentInstPointer(self)
    cdef inline void setINTR(self, unsigned char state)
    cdef inline void setHRQ(self, unsigned char state)
    cdef void handleAsyncEvent(self)
    cpdef exception(self, unsigned char exceptionId, signed int errorCode)
    cpdef handleException(self, object exception)
    cdef unsigned char parsePrefixes(self, unsigned char opcode)
    cpdef cpuDump(self)
    cpdef doInfiniteCycles(self)
    cpdef doCycle(self)
    cpdef run(self)


