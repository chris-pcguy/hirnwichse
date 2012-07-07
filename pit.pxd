
cdef class PitChannel:
    cpdef object main
    cpdef Pit pit
    cpdef unsigned char channelId, bcdMode, counterMode, counterWriteMode, \
      counterFlipFlop, timerEnabled
    cpdef unsigned int counterValue, counterStartValue
    cpdef float tempTimerValue
    cpdef mode0Func(self)
    cpdef mode2Func(self)
    cpdef timerFunc(self)
    cpdef runTimer(self)

cdef class Pit:
    cpdef object main
    cpdef tuple channels
    cpdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cpdef run(self)



