
from hirnwichse_main cimport Hirnwichse

cdef class Serial:
    cdef Hirnwichse main
    cdef void reset(self)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)


