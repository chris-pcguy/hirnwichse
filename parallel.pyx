
include "globals.pxi"


cdef class Parallel:
    cpdef object main
    cdef tuple ports
    def __init__(self, object main):
        self.main = main
        self.ports = (0x3bc, 0x3bd, 0x3be, 0x378, 0x379, 0x37a, 0x278, 0x279, 0x27a, 0x2bc, 0x2bd, 0x2be)
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            pass
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cpdef outPort(self, unsigned short ioPortAddr, unsigned char data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            pass
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cpdef run(self):
        self.main.platform.addReadHandlers(self.ports, self)
        self.main.platform.addWriteHandlers(self.ports, self)


