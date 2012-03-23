
from misc cimport Misc
from mm cimport Mm
from pic cimport Pic
from isadma cimport IsaDma
from segments cimport Segments
from registers cimport Registers
from opcodes cimport Opcodes


cdef class Cpu:
    cpdef public object main
    cdef public Registers registers
    cdef Opcodes opcodes
    cdef public unsigned char asyncEvent, opcode, cpuHalted, debugHalt, debugSingleStep
    cdef public unsigned long long cycles
    cdef unsigned char INTR, HRQ
    cdef public unsigned short savedCs
    cdef public unsigned long savedEip
    cdef unsigned long long oldCycleInc
    cdef void reset(self)
    cdef inline void saveCurrentInstPointer(self)
    cdef inline void setINTR(self, unsigned char state)
    cdef inline void setHRQ(self, unsigned char state)
    cdef void handleAsyncEvent(self)
    cdef void exception(self, unsigned char exceptionId, signed long errorCode)
    cpdef handleException(self, object exception)
    cdef unsigned char parsePrefixes(self, unsigned char opcode)
    cpdef cpuDump(self)
    cdef void doInfiniteCycles(self)
    cdef void doCycle(self)
    cdef void run(self)


