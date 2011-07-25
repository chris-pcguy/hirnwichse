##cimport numpy

cdef class MmArea:
    cpdef public object mm, main
    cpdef public long mmBaseAddr, mmAreaSize
    ##cpdef numpy.ndarray mmAreaData
    cpdef mmAreaData
    ###def __init__(self, mm, long mmBaseAddr, long mmAreaSize)
    cpdef mmAreaRead(self, long mmPhyAddr, long dataSize)
    cpdef mmAreaWrite(self, long mmPhyAddr, bytes data, long dataSize, int signed=?) # dataSize in bytes; use 'signed' only if writing 'int'



cdef class Mm:
    cpdef public object main
    cpdef list mmAreas
    ###def __init__(self, main):
    cpdef mmAddArea(self, long mmBaseAddr, long mmAreaSize)
    cpdef mmDelArea(self, long mmBaseAddr)
    cpdef mmGetArea(self, long mmAddr, long dataSize) # dataSize in bytes
    cpdef mmGetRealAddr(self, long mmAddr, int segId)
    cpdef mmPhyRead(self, long mmAddr, long dataSize) # dataSize in bytes
    cpdef mmRead(self, long mmAddr, long dataSize, int segId=?) # dataSize in bytes
    cpdef mmPhyWrite(self, long mmAddr, bytes data, long dataSize) # dataSize in bytes
    cpdef mmWrite(self, long mmAddr, bytes data, long dataSize, int segId=?) # dataSize in bytes
    cpdef mmWriteValue(self, long mmAddr, long data, long dataSize, int segId=?, int signed=?) # dataSize in bytes


