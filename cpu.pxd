
cdef class Cpu:
    cpdef public object main, registers, opcodes
    cdef public unsigned long long cycles
    cdef public unsigned char opcode, cpuHalted, debugHalt, debugSingleStep, A20Active, protectedModeOn, HRQ
    cdef unsigned char asyncEvent, irqEvent
    cdef unsigned long long savedCs, savedEip, oldCycles
    cpdef object cpuThread
    cpdef reset(self)
    cpdef unsigned char getA20State(self)
    cpdef setA20State(self, unsigned char state)
    cpdef setHRQ(self, unsigned char state)
    cpdef setIrq(self, unsigned char state)
    cpdef unsigned long long getCurrentOpcodeAddr(self)
    cpdef long long getCurrentOpcode(self, unsigned char numBytes, unsigned char signed) # numBytes in bytes
    cpdef long long getCurrentOpcodeAdd(self, unsigned char numBytes, unsigned char signed) # numBytes in bytes
    cpdef tuple getCurrentOpcodeWithAddr(self, unsigned char getAddr, unsigned char numBytes, unsigned char signed) # numBytes in bytes
    cpdef tuple getCurrentOpcodeAddWithAddr(self, unsigned char getAddr, unsigned char numBytes, unsigned char signed) # numBytes in bytes
    cpdef unsigned char handleAsyncEvent(self) # return True if irq was handled, otherwise False
    cpdef exception(self, unsigned char exceptionId, long errorCode)
    cpdef handleException(self, object exception)
    cpdef unsigned char isInProtectedMode(self)
    cpdef unsigned char parsePrefixes(self, unsigned char opcode)
    cpdef doInfiniteCycles(self)
    cpdef doCycle(self)
    cpdef runCDEF(self)
    cpdef run(self)


