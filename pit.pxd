

cdef class PitChannel:
    cpdef object main, counterModeTimer
    cdef Pit pit
    cdef unsigned char channelId, counterFormat, counterMode, counterWriteMode, counterFlipFlop
    cdef unsigned long counterValue, actualCounterValue
    cdef float tempTimerValue
    cdef reset(self)
    cpdef mode0Func(self)
    cpdef mode2Func(self)
    cpdef runTimer(self)
    cdef run(self)

cdef class Pit:
    cpdef object main
    cdef tuple channels
    cdef unsigned char channel
    cdef reset(self)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef run(self)



