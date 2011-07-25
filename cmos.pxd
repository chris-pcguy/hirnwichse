cimport misc ##, numpy

cdef class Cmos:
    cpdef object main
    ##cpdef numpy.ndarray cmosData
    cpdef cmosData
    cdef int cmosIndex
    ###def __init__(self, object main)
    cpdef long inPort(self, long ioPortAddr, int dataSize)
    cpdef outPort(self, long ioPortAddr, data, int dataSize)
    cpdef run(self)



