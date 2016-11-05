
from libc.stdint cimport *
from libc.math cimport lround
from cpython.ref cimport PyObject

from hirnwichse_main cimport Hirnwichse
from pic cimport Pic
from misc cimport Misc
from pit cimport PitChannel
from mm cimport ConfigSpace
from posix.unistd cimport usleep

cdef class Cmos:
    cdef Hirnwichse main
    cdef ConfigSpace configSpace
    cdef PyObject *rtcChannel
    cdef object dt, oldDt
    cdef uint8_t cmosIndex, equipmentDefaultValue, statusB
    cdef uint32_t rtcDelay
    cdef inline void setEquipmentDefaultValue(self, uint8_t value):
        self.equipmentDefaultValue = value
    cdef inline uint8_t getEquipmentDefaultValue(self):
        return self.equipmentDefaultValue
    cdef uint16_t decToBcd(self, uint16_t dec)
    cdef inline uint32_t readValue(self, uint8_t index, uint8_t size) nogil
    cdef inline void writeValue(self, uint8_t index, uint32_t value, uint8_t size) nogil
    cdef void reset(self)
    cdef void updateTime(self)
    cdef void secondsThreadFunc(self)
    cdef void uipThreadFunc(self)
    cdef void periodicFunc(self)
    cdef void makeCheckSum(self) nogil
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil
    cdef void run(self)



