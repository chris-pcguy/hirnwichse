
from libc.stdint cimport *

from hirnwichse_main cimport Hirnwichse

cdef class Parallel:
    cdef Hirnwichse main
    cdef void reset(self)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void run(self)


