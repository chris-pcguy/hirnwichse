
cdef class Misc:
    cpdef object main
    cdef unsigned long int getBitMask80(self, unsigned char maskSize)
    cdef unsigned long int getBitMaskFF(self, unsigned char maskSize)
    cdef unsigned int checksum(self, bytes data) # data is bytes
    cdef unsigned long int decToBcd(self, unsigned char dec)
    cdef unsigned long int bcdToDec(self, unsigned char bcd)
    cdef unsigned long int reverseByteOrder(self, unsigned int value, unsigned char valueSize)
    cpdef object createThread(self, object threadFunc, unsigned char startIt)


