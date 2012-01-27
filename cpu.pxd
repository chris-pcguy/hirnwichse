
from misc cimport Misc
from mm cimport Mm
from pic cimport Pic
from isadma cimport IsaDma
from segments cimport Segments
from registers cimport Registers
from opcodes cimport Opcodes


cdef class Cpu:
    cpdef public object main, _pyroDaemon
    cdef public Registers registers
    cdef Opcodes opcodes
    cpdef public str _pyroId
    cdef public unsigned char asyncEvent, opcode, cpuHalted, debugHalt, debugSingleStep
    cdef public unsigned long long cycles
    cdef unsigned char INTR, HRQ
    cdef unsigned short savedCs
    cdef unsigned long savedEip
    cdef reset(self)
    cdef saveCurrentInstPointer(self)
    cpdef setINTR(self, unsigned char state)
    cpdef setHRQ(self, unsigned char state)
    cdef handleAsyncEvent(self)
    cdef exception(self, unsigned char exceptionId, long errorCode)
    cpdef handleException(self, object exception)
    cdef unsigned char parsePrefixes(self, unsigned char opcode)
    cpdef doInfiniteCycles(self)
    cdef doCycle(self)
    cpdef run(self)


