

cdef class Misc:
    cdef unsigned int checksum(self, bytes data) # data is bytes
    cdef unsigned short decToBcd(self, unsigned short dec)
    cdef unsigned short bcdToDec(self, unsigned short bcd)
    cdef unsigned long int reverseByteOrder(self, unsigned long int value, unsigned char valueSize)
    cdef unsigned short calculateInterruptErrorcode(self, unsigned char num, unsigned char idt, unsigned char ext)
    cpdef object createThread(self, object threadFunc, unsigned char startIt)


