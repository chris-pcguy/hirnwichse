
from libc.stdint cimport *
from cpython.ref cimport PyObject, Py_INCREF

from hirnwichse_main cimport Hirnwichse
from cmos cimport Cmos
from pic cimport Pic
from ps2 cimport PS2
from posix.unistd cimport usleep

cdef class PitChannel:
    cpdef object threadObject
    cdef Pit pit
    cdef uint8_t channelId, bcdMode, counterMode, counterWriteMode, \
      counterFlipFlop, timerEnabled, readBackStatusValue, readBackStatusIssued, resetChannel
    cdef uint32_t counterValue, counterStartValue, counterLatchValue, tempTimerValue
    cdef void readBackCount(self) nogil
    cdef void readBackStatus(self) nogil
    cdef void mode0Func(self) nogil
    cdef void mode2Func(self) nogil
    cpdef timerFunc(self)
    cpdef runTimer(self)

cdef class Pit:
    cdef Hirnwichse main
    cdef PyObject *channels[3]
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil
    cdef void run(self)



