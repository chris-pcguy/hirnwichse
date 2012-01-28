
from misc cimport Misc
from libc.stdlib cimport calloc, malloc, free
from libc.string cimport strncpy, memcpy, memset


cdef class MmArea:
    cpdef object main
    cdef Mm mm
    cdef unsigned char mmReadOnly
    cdef unsigned long long mmBaseAddr, mmAreaSize, mmEndAddr
    cdef char *mmAreaData
    cdef mmResetAreaData(self)
    cpdef mmFreeAreaData(self)
    cdef mmSetReadOnly(self, unsigned char mmReadOnly)
    cdef bytes mmAreaRead(self, unsigned long long mmAddr, unsigned long long dataSize)
    cdef mmAreaWrite(self, unsigned long long mmAddr, bytes data, unsigned long long dataSize) # dataSize(type int) is count in bytes
    cpdef run(self)


cdef class Mm:
    cpdef object main
    cdef list mmAreas
    cdef mmAddArea(self, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly, MmArea mmAreaObject)
    cdef unsigned char mmDelArea(self, unsigned long long mmBaseAddr)
    cdef MmArea mmGetSingleArea(self, long long mmAddr, unsigned long long dataSize)
    cdef list mmGetAreas(self, long long mmAddr, unsigned long long dataSize)
    cdef bytes mmPhyRead(self, long long mmAddr, unsigned long long dataSize)
    cdef long long mmPhyReadValueSigned(self, long long mmAddr, unsigned char dataSize)
    cdef unsigned long long mmPhyReadValueUnsigned(self, long long mmAddr, unsigned char dataSize)
    cdef mmPhyWrite(self, long long mmAddr, bytes data, unsigned long long dataSize)
    cdef unsigned long long mmPhyWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize)


cdef class ConfigSpace:
    cpdef object main
    cdef char *csData
    cdef unsigned long csSize
    cdef csResetData(self)
    cpdef csFreeData(self)
    cdef bytes csRead(self, unsigned long offset, unsigned long size)
    cdef csWrite(self, unsigned long offset, bytes data, unsigned long size)
    cdef unsigned long long csReadValueUnsigned(self, unsigned long offset, unsigned long size)
    cdef unsigned long long csReadValueUnsignedBE(self, unsigned long offset, unsigned long size)
    cdef long long csReadValueSigned(self, unsigned long offset, unsigned long size)
    cdef long long csReadValueSignedBE(self, unsigned long offset, unsigned long size)
    cdef unsigned long long csWriteValue(self, unsigned long offset, unsigned long long data, unsigned long size)
    cdef unsigned long long csWriteValueBE(self, unsigned long offset, unsigned long long data, unsigned long size)
    cdef unsigned long long csAddValue(self, unsigned long offset, unsigned long long data, unsigned long size)
    cdef unsigned long long csSubValue(self, unsigned long offset, unsigned long long data, unsigned long size)
    cpdef run(self)







