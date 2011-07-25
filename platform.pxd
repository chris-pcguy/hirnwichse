cdef class Platform:
    cpdef public object main, cmos, isadma
    cpdef dict readHandlers
    cpdef dict writeHandlers
    ##def __init__(self, main):
    cpdef addHandlers(self, tuple portNums, portHandler)
    cpdef addReadHandlers(self, tuple portNums, portHandler)
    cpdef addWriteHandlers(self, tuple portNums, portHandler)
    cpdef delHandlers(self, tuple portNums)
    cpdef delReadHandlers(self, tuple portNums)
    cpdef delWriteHandlers(self, tuple portNums)
    cpdef inPort(self, int portNum, int dataSize)
    cpdef outPort(self, int portNum, long data, int dataSize)
    cpdef loadRomToMem(self, romFileName, long mmAddr, int romSize)
    cpdef loadRom(self, str romFileName, long mmAddr, int isRomOptional)
    cpdef run(self, int memSize)
    cpdef runDevices(self)
    



