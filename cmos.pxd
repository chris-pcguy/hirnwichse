
cimport mm


cdef class Cmos:
    cpdef mm.ConfigSpace configSpace
    cpdef object main, dt
    cdef unsigned char cmosIndex
    cdef unsigned long readValue(self, unsigned char index, unsigned char size)
    cdef writeValue(self, unsigned char index, unsigned long value, unsigned char size)
    cdef reset(self)
    cpdef updateTime(self)
    cpdef makeCheckSum(self)
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned char data, unsigned char dataSize)
    cpdef run(self)



