

cdef class PitChannel:
    cpdef public object main, counterModeTimer
    cdef public Pit pit
    cdef public unsigned char channelId, counterFormat, counterMode, counterWriteMode, counterFlipFlop
    cdef public unsigned long counterValue, actualCounterValue
    cdef public float tempTimerValue
    cdef reset(self)
    cpdef mode0Func(self)
    cpdef mode2Func(self)
    cpdef runTimer(self)
    cdef run(self)

cdef class Pit:
    cpdef public object main
    cdef public tuple channels
    cdef public unsigned char channel
    cdef reset(self)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef run(self)



