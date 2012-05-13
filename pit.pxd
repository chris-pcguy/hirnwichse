
from pic cimport Pic
from ps2 cimport PS2

cdef class PitChannel:
    cpdef object main, timerThread
    cpdef Pit pit
    cdef public unsigned char channelId, bcdMode, counterMode, counterWriteMode, \
      counterFlipFlop, timerEnabled
    cdef public unsigned int counterValue, counterStartValue
    cdef double tempTimerValue
    cpdef mode0Func(self)
    cpdef mode2Func(self)
    cpdef timerFunc(self)
    cpdef runTimer(self)
    cpdef run(self)

cdef class Pit:
    cpdef object main
    cdef tuple channels
    cpdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cpdef run(self)



