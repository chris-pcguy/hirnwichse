
cdef class Vga:
    cpdef object main
    cpdef inPort(self, long ioPortAddr, int dataSize)
    cpdef outPort(self, long ioPortAddr, long data, int dataSize)
    cpdef run(self)


