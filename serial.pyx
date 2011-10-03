
include "globals.pxi"


cdef class Serial:
    cdef object main
    cdef tuple ports
    def __init__(self, object main):
        self.main = main
        self.ports = (0x3f8, 0x3f9, 0x3fa, 0x3fb, 0x3fc, 0x3fd, 0x3fe, 0x3ff, \
                      0x2f8, 0x2f9, 0x2fa, 0x2fb, 0x2fc, 0x2fd, 0x2fe, 0x2ff, \
                      0x3e8, 0x3e9, 0x3ea, 0x3eb, 0x3ec, 0x3ed, 0x3ee, 0x3ef, \
                      0x2e8, 0x2e9, 0x2ea, 0x2eb, 0x2ec, 0x2ed, 0x2ee, 0x2ef)
    def inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            pass
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, unsigned short ioPortAddr, int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            pass
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers(self.ports, self.inPort)
        self.main.platform.addWriteHandlers(self.ports, self.outPort)


