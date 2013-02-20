
cdef class PitChannel:
    cpdef object main
    cdef Pit pit
    cdef unsigned char channelId, bcdMode, counterMode, counterWriteMode, \
      counterFlipFlop, timerEnabled
    cdef unsigned int counterValue, counterStartValue, counterLatchValue
    cdef float tempTimerValue
    cpdef mode0Func(self)
    cpdef mode2Func(self)
    cpdef timerFunc(self)
    cpdef runTimer(self)

cdef class Pit:
    cpdef object main
    cdef tuple channels
    cpdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cpdef run(self)



