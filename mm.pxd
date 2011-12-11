

cdef class MmArea:
    cpdef public object main, mm
    #cpdef object mmAreaData
    cdef unsigned char mmReadOnly
    cdef public unsigned long long mmBaseAddr, mmAreaSize, mmEndAddr
    cdef char *mmAreaData
    cpdef mmFreeAreaData(self)
    cpdef mmSetReadOnly(self, unsigned char mmReadOnly)
    cpdef bytes mmAreaRead(self, unsigned long long mmAddr, unsigned long long dataSize)
    cpdef mmAreaWrite(self, unsigned long long mmAddr, bytes data, unsigned long long dataSize) # dataSize(type int) is count in bytes
    cpdef run(self)


cdef class Mm:
    cpdef public object main
    cdef list mmAreas
    cpdef mmAddArea(self, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly, object mmAreaObject)
    cpdef unsigned char mmDelArea(self, unsigned long long mmBaseAddr)
    cpdef object mmGetSingleArea(self, long long mmAddr, unsigned long long dataSize) # dataSize in bytes
    cpdef list mmGetAreas(self, long long mmAddr, unsigned long long dataSize) # dataSize in bytes
    cpdef unsigned long long mmGetRealAddr(self, long long mmAddr, unsigned short segId, unsigned char allowOverride)
    cpdef bytes mmPhyRead(self, long long mmAddr, unsigned long long dataSize)
    cpdef bytes mmRead(self, long long mmAddr, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride)
    cpdef mmPhyReadValue(self, long long mmAddr, unsigned long long dataSize, unsigned char signed)
    cpdef mmReadValue(self, long long mmAddr, unsigned long long dataSize, unsigned short segId, unsigned char signed, unsigned char allowOverride) # dataSize in bytes
    cpdef mmPhyWrite(self, long long mmAddr, bytes data, unsigned long long dataSize)
    cpdef mmWrite(self, long long mmAddr, bytes data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride)
    cpdef unsigned long long mmPhyWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize)
    cpdef unsigned long long mmWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride)
    cpdef unsigned long long mmWriteValueWithOp(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride, unsigned char valueOp)



cdef class ConfigSpace:
    cpdef object csData
    cdef unsigned long csSize
    cpdef bytes csRead(self, unsigned long offset, unsigned long size)
    cpdef csWrite(self, unsigned long offset, bytes data, unsigned long size) # dataSize in bytes; use 'signed' only if writing 'int'
    cpdef unsigned long long csReadValue(self, unsigned long offset, unsigned long size) # dataSize in bytes
    cpdef unsigned long long csWriteValue(self, unsigned long offset, unsigned long long data, unsigned long size) # dataSize in bytes
    cpdef unsigned long long csAddValue(self, unsigned long offset, unsigned long long data, unsigned long size) # dataSize in bytes, data==int
    cpdef unsigned long long csSubValue(self, unsigned long offset, unsigned long long data, unsigned long size) # dataSize in bytes, data==int








