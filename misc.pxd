
cdef class Misc:
    cpdef object main
    cdef unsigned long long getBitMask80(self, unsigned char maskSize)
    cdef unsigned long long getBitMaskFF(self, unsigned char maskSize)
    cdef unsigned long checksum(self, bytes data) # data is bytes
    cdef unsigned long long decToBcd(self, unsigned char dec)
    cdef unsigned long long bcdToDec(self, unsigned char bcd)
    cdef unsigned long long reverseByteOrder(self, unsigned long value, unsigned char valueSize)
    cdef bytes generateString(self, unsigned char firstChar, unsigned char lastChar, unsigned short stringLen)
    cpdef object createThread(self, object threadFunc, unsigned char startIt)


