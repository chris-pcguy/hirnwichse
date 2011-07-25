
cdef class Vga:
    def __init__(self, object main):
        self.main = main
    cpdef inPort(self, long ioPortAddr, int dataSize):
        if (dataSize == 8):
            pass
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cpdef outPort(self, long ioPortAddr, long data, int dataSize):
        if (dataSize == 8):
            pass
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cpdef run(self):
        pass


