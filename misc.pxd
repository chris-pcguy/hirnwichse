
include "globals.pxi"

DEF BITMASKS_80 = (None, 0x80, 0x8000, None, 0x80000000, None, None, None, 0x8000000000000000)
DEF BITMASKS_FF = (None, 0xff, 0xffff, None, 0xffffffff, None, None, None, 0xffffffffffffffff)



cdef class Misc:
    cpdef object main
    cdef inline unsigned long int getBitMask80(self, unsigned char maskSize):
        return BITMASKS_80[maskSize]
    cdef inline unsigned long int getBitMaskFF(self, unsigned char maskSize):
        return BITMASKS_FF[maskSize]
    cdef unsigned int checksum(self, bytes data) # data is bytes
    cdef unsigned long int decToBcd(self, unsigned char dec)
    cdef unsigned long int bcdToDec(self, unsigned char bcd)
    cdef unsigned long int reverseByteOrder(self, unsigned int value, unsigned char valueSize)
    cpdef object createThread(self, object threadFunc, unsigned char startIt)


