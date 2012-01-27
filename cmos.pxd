
from mm cimport ConfigSpace


cdef class Cmos:
    cdef ConfigSpace configSpace
    cpdef public object main, _pyroDaemon
    cpdef object dt
    cpdef public str _pyroId
    cdef unsigned char cmosIndex, equipmentDefaultValue
    cpdef setEquipmentDefaultValue(self, unsigned char value)
    cpdef unsigned char getEquipmentDefaultValue(self)
    cpdef unsigned long readValue(self, unsigned char index, unsigned char size)
    cpdef writeValue(self, unsigned char index, unsigned long value, unsigned char size)
    cdef reset(self)
    cdef updateTime(self)
    cdef makeCheckSum(self)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef run(self)



