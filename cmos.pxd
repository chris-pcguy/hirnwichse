
from hirnwichse_main cimport Hirnwichse
from pic cimport Pic
from misc cimport Misc
from pit cimport PitChannel
from mm cimport ConfigSpace
from posix.unistd cimport usleep

cdef class Cmos:
    cdef Hirnwichse main
    cdef ConfigSpace configSpace
    cdef PitChannel rtcChannel
    cpdef object dt, oldDt, secondsThread
    cdef unsigned char cmosIndex, equipmentDefaultValue, statusB
    cdef unsigned int rtcDelay
    cdef inline void setEquipmentDefaultValue(self, unsigned char value):
        self.equipmentDefaultValue = value
    cdef inline unsigned char getEquipmentDefaultValue(self):
        return self.equipmentDefaultValue
    cdef inline unsigned int readValue(self, unsigned char index, unsigned char size)
    cdef inline void writeValue(self, unsigned char index, unsigned int value, unsigned char size)
    cdef void reset(self)
    cdef void updateTime(self)
    cpdef secondsThreadFunc(self)
    cpdef uipThreadFunc(self)
    cdef void periodicFunc(self)
    cdef void makeCheckSum(self)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)



