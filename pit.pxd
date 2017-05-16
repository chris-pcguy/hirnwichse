
from libc.stdint cimport *
from libc.math cimport lround
from cpython.ref cimport PyObject, Py_INCREF
from posix.unistd cimport usleep

from hirnwichse_main cimport Hirnwichse
from cmos cimport Cmos
from pic cimport Pic
from ps2 cimport PS2

cdef class PitChannel:
    cdef object threadObject
    cdef Pit pit
    cdef uint8_t channelId, bcdMode, counterMode, localCounterMode, counterWriteMode, \
      counterFlipFlop, timerEnabled, readBackStatusValue, readBackStatusIssued, resetChannel
    cdef uint32_t counterValue, counterStartValue, counterLatchValue, tempTimerValue
    cdef uint16_t bcdToDec(self, uint16_t bcd)
    cdef void readBackCount(self)
    cdef void readBackStatus(self)
    cdef void mode0Func(self)
    cdef void mode2Func(self)
    cdef void timerFunc(self)
    cdef void runTimer(self)

cdef class Pit:
    cdef Hirnwichse main
    cdef PyObject *channels[3]
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void run(self)



