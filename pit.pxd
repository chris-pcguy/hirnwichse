
from hirnwichse_main cimport Hirnwichse
from cmos cimport Cmos
from pic cimport Pic
from ps2 cimport PS2
from posix.unistd cimport usleep

cdef class PitChannel:
    cpdef object threadObject
    cdef Pit pit
    cdef unsigned char channelId, bcdMode, counterMode, counterWriteMode, \
      counterFlipFlop, timerEnabled, readBackStatusValue, readBackStatusIssued, resetChannel
    cdef unsigned int counterValue, counterStartValue, counterLatchValue, tempTimerValue
    cdef void readBackCount(self) nogil
    cdef void readBackStatus(self) nogil
    cdef void mode0Func(self)
    cdef void mode2Func(self)
    cpdef timerFunc(self)
    cpdef runTimer(self)

cdef class Pit:
    cdef Hirnwichse main
    cdef tuple channels
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)



