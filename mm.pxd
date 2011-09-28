

cdef class MmArea:
    cdef public object main, mm
    cdef object mmAreaData
    cdef unsigned char mmReadOnly
    cdef public unsigned long long mmBaseAddr, mmAreaSize
    ##def __init__(self, object mmObj, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly)
    cpdef mmSetReadOnly(self, unsigned char mmReadOnly)
    cpdef mmAreaRead(self, unsigned long long mmPhyAddr, unsigned long long dataSize)
    cpdef mmAreaWrite(self, unsigned long long mmPhyAddr, bytes data, unsigned long long dataSize) # dataSize(type int) in bytes



cdef class Mm:
    cdef public object main
    cdef list mmAreas
    ##def __init__(self, object main)
    cpdef mmAddArea(self, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly=*, object mmAreaObject=*)
    cpdef mmDelArea(self, unsigned long long mmBaseAddr)
    cpdef mmGetSingleArea(self, long long mmAddr, unsigned long long dataSize) # dataSize in bytes
    cpdef mmGetAreas(self, long long mmAddr, unsigned long long dataSize) # dataSize in bytes
    cpdef mmGetRealAddr(self, long long mmAddr, unsigned short segId, unsigned char allowOverride=*)
    cpdef mmPhyRead(self, long long mmAddr, unsigned long long dataSize, int ignoreFail=*) # dataSize in bytes
    cpdef mmPhyReadValue(self, long long mmAddr, unsigned long long dataSize, int signed=*) # dataSize in bytes
    cpdef mmRead(self, long long mmAddr, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes
    cpdef mmReadValue(self, long long mmAddr, unsigned long long dataSize, unsigned short segId=*, int signed=*, unsigned char allowOverride=*) # dataSize in bytes
    cpdef mmPhyWrite(self, long long mmAddr, bytes data, unsigned long long dataSize) # dataSize in bytes
    cpdef mmPhyWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize) # dataSize in bytes
    cpdef mmWrite(self, long long mmAddr, bytes data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes
    cpdef mmWriteValueWithOp(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*, unsigned char valueOp=*) # dataSize in bytes
    cpdef mmWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes
    cpdef mmAddValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef mmAdcValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef mmSubValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef mmSbbValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef mmAndValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef mmOrValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    cpdef mmXorValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=*, unsigned char allowOverride=*) # dataSize in bytes, data==int
    


cdef class ConfigSpace:
    cdef object main, csData
    cdef unsigned long long csSize
    ##def __init__(self, int csSize, object main)
    cpdef csRead(self, unsigned long long offset, unsigned long long size)
    cpdef csWrite(self, unsigned long long offset, bytes data, unsigned long long size) # dataSize in bytes; use 'signed' only if writing 'int'
    cpdef csReadValue(self, unsigned long long offset, unsigned long long size, int signed=*) # dataSize in bytes
    cpdef csWriteValue(self, unsigned long long offset, unsigned long long data, unsigned long long size) # dataSize in bytes
    cpdef csAddValue(self, unsigned long long offset, unsigned long long data, unsigned long long size) # dataSize in bytes, data==int
    cpdef csSubValue(self, unsigned long long offset, unsigned long long data, unsigned long long size) # dataSize in bytes, data==int








