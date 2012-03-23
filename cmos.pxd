
from misc cimport Misc
from mm cimport ConfigSpace


cdef class Cmos:
    cdef ConfigSpace configSpace
    cpdef object main, dt, oldDt
    cdef unsigned char cmosIndex, equipmentDefaultValue
    cdef inline void setEquipmentDefaultValue(self, unsigned char value)
    cdef unsigned char getEquipmentDefaultValue(self)
    cdef unsigned int readValue(self, unsigned char index, unsigned char size)
    cdef inline void writeValue(self, unsigned char index, unsigned int value, unsigned char size)
    cdef void reset(self)
    cdef void updateTime(self)
    cdef void makeCheckSum(self)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)



