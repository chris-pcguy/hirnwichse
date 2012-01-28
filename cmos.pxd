
from misc cimport Misc
from mm cimport ConfigSpace


cdef class Cmos:
    cdef ConfigSpace configSpace
    cpdef object main, dt
    cdef unsigned char cmosIndex, equipmentDefaultValue
    cdef setEquipmentDefaultValue(self, unsigned char value)
    cdef unsigned char getEquipmentDefaultValue(self)
    cdef unsigned long readValue(self, unsigned char index, unsigned char size)
    cdef writeValue(self, unsigned char index, unsigned long value, unsigned char size)
    cdef reset(self)
    cdef updateTime(self)
    cdef makeCheckSum(self)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef run(self)



