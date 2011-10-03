

cdef class MmArea:
    cdef public object main, mm
    cdef object mmAreaData
    cdef unsigned char mmReadOnly
    cdef public unsigned long long mmBaseAddr, mmAreaSize
    ##def __init__(self, object mmObj, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly)
    cpdef public mmSetReadOnly(self, unsigned char mmReadOnly)
    cpdef public bytes mmAreaRead(self, unsigned long long mmPhyAddr, unsigned long long dataSize)
    cpdef public mmAreaWrite(self, unsigned long long mmPhyAddr, bytes data, unsigned long long dataSize) # dataSize(type int) in bytes



cdef class Mm:
    cdef public object main
    cdef list mmAreas
    ##def __init__(self, object main)
    cpdef public mmAddArea(self, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly=*, object mmAreaObject=*)
    cpdef public unsigned char mmDelArea(self, unsigned long long mmBaseAddr)
    cpdef public object mmGetSingleArea(self, long long mmAddr, unsigned long long dataSize) # dataSize in bytes
    cpdef public list mmGetAreas(self, long long mmAddr, unsigned long long dataSize) # dataSize in bytes
    cpdef public unsigned long long mmGetRealAddr(self, long long mmAddr, unsigned short segId, unsigned char allowOverride=*)
    cpdef public bytes mmPhyRead(self, long long mmAddr, unsigned long long dataSize, int ignoreFail=*) # dataSize in bytes
    cpdef public long long mmPhyReadValue(self, long long mmAddr, unsigned long long dataSize, int signed=*) # dataSize in bytes
    cpdef public bytes mmRead(self, long long mmAddr, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes
    cpdef public long long mmReadValue(self, long long mmAddr, unsigned long long dataSize, unsigned short segId=*, int signed=*, unsigned char allowOverride=*) # dataSize in bytes
    cpdef public mmPhyWrite(self, long long mmAddr, bytes data, unsigned long long dataSize) # dataSize in bytes
    cpdef public unsigned long long mmPhyWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize) # dataSize in bytes
    cpdef public mmWrite(self, long long mmAddr, bytes data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes
    cpdef public unsigned long long mmWriteValueWithOp(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*, unsigned char valueOp=*) # dataSize in bytes
    cpdef public unsigned long long mmWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes
    cpdef public unsigned long long mmAddValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef public unsigned long long mmAdcValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef public unsigned long long mmSubValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef public unsigned long long mmSbbValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef public unsigned long long mmAndValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef public unsigned long long mmOrValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef public unsigned long long mmXorValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    


cdef class ConfigSpace:
    cdef object main, csData
    cdef unsigned long long csSize
    ##def __init__(self, int csSize, object main)
    cpdef public bytes csRead(self, unsigned long long offset, unsigned long long size)
    cpdef public csWrite(self, unsigned long long offset, bytes data, unsigned long long size) # dataSize in bytes; use 'signed' only if writing 'int'
    cpdef public long long csReadValue(self, unsigned long long offset, unsigned long long size, int signed=*) # dataSize in bytes
    cpdef public unsigned long long csWriteValue(self, unsigned long long offset, unsigned long long data, unsigned long long size) # dataSize in bytes
    cpdef public unsigned long long csAddValue(self, unsigned long long offset, unsigned long long data, unsigned long long size) # dataSize in bytes, data==int
    cpdef public unsigned long long csSubValue(self, unsigned long long offset, unsigned long long data, unsigned long long size) # dataSize in bytes, data==int








