
cdef class Floppy:
    cpdef object main
    ##def __init__(self, object main)
    cpdef inPort(self, long ioPortAddr, int dataSize)
    cpdef outPort(self, long ioPortAddr, long data, int dataSize)
    cpdef run(self)


