
from libc.stdint cimport *

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
    cdef uint8_t cmosIndex, equipmentDefaultValue, statusB
    cdef uint32_t rtcDelay
    cdef inline void setEquipmentDefaultValue(self, uint8_t value):
        self.equipmentDefaultValue = value
    cdef inline uint8_t getEquipmentDefaultValue(self):
        return self.equipmentDefaultValue
    cdef inline uint32_t readValue(self, uint8_t index, uint8_t size) nogil
    cdef inline void writeValue(self, uint8_t index, uint32_t value, uint8_t size) nogil
    cdef void reset(self)
    cdef void updateTime(self) nogil
    cpdef secondsThreadFunc(self)
    cpdef uipThreadFunc(self)
    cdef void periodicFunc(self) nogil
    cdef void makeCheckSum(self) nogil
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil
    cdef void run(self)



