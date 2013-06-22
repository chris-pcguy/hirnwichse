
cdef class Misc:
    cpdef object main
    cdef unsigned int checksum(self, bytes data) # data is bytes
    cdef unsigned short decToBcd(self, unsigned short dec)
    cdef unsigned short bcdToDec(self, unsigned short bcd)
    cdef unsigned int reverseByteOrder(self, unsigned int value, unsigned char valueSize)
    cdef unsigned char calculateInterruptErrorcode(self, unsigned char num, unsigned char idt, unsigned char ext)
    cpdef object createThread(self, object threadFunc, unsigned char startIt)


