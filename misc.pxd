##class ChemuException(Exception):
##    pass

cdef class Misc:
    cpdef object main
    cpdef unsigned long long getBitMask7F(self, unsigned char maskSize)
    cpdef unsigned long long getBitMask80(self, unsigned char maskSize)
    cpdef unsigned long long getBitMaskFF(self, unsigned char maskSize)
    cpdef unsigned long checksum(self, bytes data) # data is bytes
    cpdef unsigned long long decToBcd(self, unsigned char dec)
    cpdef unsigned long long bcdToDec(self, unsigned char bcd)
    cpdef unsigned long long reverseByteOrder(self, unsigned long value, unsigned char valueSize)
    cpdef object createTimer(self, float seconds, object timerFunc, unsigned char startIt)
    cpdef object createThread(self, object threadFunc, unsigned char startIt)


