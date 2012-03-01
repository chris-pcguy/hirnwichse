
from pic cimport Pic
from ps2 cimport PS2

cdef class PitChannel:
    cpdef object main, counterModeTimer
    cdef Pit pit
    cdef unsigned char channelId, counterFormat, counterMode, counterWriteMode, counterFlipFlop
    cdef unsigned long counterValue, counterStartValue
    cdef float tempTimerValue
    cdef void reset(self)
    cpdef mode0Func(self)
    cpdef mode2Func(self)
    cpdef runTimer(self)
    cdef void run(self)

cdef class Pit:
    cpdef object main
    cdef tuple channels
    cdef unsigned char channel
    cdef void reset(self)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef void run(self)



