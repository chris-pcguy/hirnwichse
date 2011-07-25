import struct, time

import chemu
cimport registers, opcodes, misc



cdef class Cpu:
    #cdef object main
    #cdef object registers
    #cdef object opcodes
    cpdef public object main, registers
    cpdef object opcodes
    
    cpdef public long savedCs, savedEip, savedAddr
    cpdef public int cpuHalted, opcode
    
    ##def __init__(self, object main):
    cpdef reset(self)
    cpdef getCurrentOpcodeAddr(self)
    cpdef getCurrentOpcode(self, int numBytes=?, int signed=?)
    cpdef getCurrentOpcodeAdd(self, int numBytes=?, int signed=?) # numBytes in bytes
    cpdef getCurrentOpcodeAddEip(self, int signed=?)
    cpdef exception(self, int exceptionId)
    cpdef parsePrefixes(self, int opcode)
    cpdef doInfiniteCycles(self)
    cpdef doCycle(self)
    cpdef run(self)



