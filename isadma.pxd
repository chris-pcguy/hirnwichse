cimport misc

cdef class Channel:
    cpdef object main, isadma, controller
    cpdef int channelMasked
    cpdef long startAddress, transferBytes
    ###def __init__(self, controller)
    pass

cdef class Controller:
    cpdef public object main, isadma
    cpdef tuple channel
    cpdef int flipFlop
    ###def __init__(self, dma)
    cpdef reset(self)
    cpdef maskChannel(self, int channelNum, int maskIt)
    cpdef setAddrByte(self, int channelNum, long data)
    cpdef setCountByte(self, int channelNum, long data)


cdef class ISADma:
    cpdef public object main
    cpdef object controller
    cpdef tuple ioMasterControllerPorts, ioSlaveControllerPorts
    ###def __init__(self, main)
    cpdef inPortMaster(self, long ioPortAddr, int dataSize)
    cpdef outPortMaster(self, long ioPortAddr, long data, int dataSize)
    cpdef inPortSlave(self, long ioPortAddr, int dataSize)
    cpdef outPortSlave(self, long ioPortAddr, long data, int dataSize)
    cpdef run(self)



