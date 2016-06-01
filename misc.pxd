
from libc.stdint cimport *

cdef class Misc:
    cdef uint32_t checksum(self, bytes data) nogil # data is bytes
    cdef uint16_t decToBcd(self, uint16_t dec)
    cdef uint16_t bcdToDec(self, uint16_t bcd)
    cdef uint64_t reverseByteOrder(self, uint64_t value, uint8_t valueSize)
    cdef uint16_t calculateInterruptErrorcode(self, uint8_t num, uint8_t idt, uint8_t ext) nogil
    cpdef object createThread(self, object threadFunc, uint8_t startIt)


