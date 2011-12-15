
from mm cimport Mm
from segments cimport Segments
from registers cimport Registers
from opcodes cimport Opcodes
from cputrace cimport Trace


cdef class Cpu:
    cpdef public object main
    cdef public Registers registers
    cdef public Opcodes opcodes
    cdef public Trace trace
    cdef public unsigned long long cycles
    cdef public unsigned char asyncEvent, opcode, cpuHalted, debugHalt, debugSingleStep, INTR, HRQ
    cdef unsigned long savedCs, savedEip
    cdef reset(self)
    cdef saveCurrentInstPointer(self)
    cdef setINTR(self, unsigned char state)
    cdef setHRQ(self, unsigned char state)
    cdef unsigned char handleAsyncEvent(self) # return True if irq was handled, otherwise False
    cdef exception(self, unsigned char exceptionId, long errorCode)
    cdef handleException(self, object exception)
    cdef unsigned char parsePrefixes(self, unsigned char opcode)
    cdef doInfiniteCycles(self)
    cdef doCycle(self)
    cdef run(self)


