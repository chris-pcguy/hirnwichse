
from misc cimport Misc
from libc.stdlib cimport calloc, malloc, free
from libc.string cimport strncpy, memcpy, memset, memmove


cdef class MmArea:
    cpdef object main
    cdef Mm mm
    cdef unsigned char mmReadOnly
    cdef unsigned int mmBaseAddr, mmAreaSize
    cdef unsigned long int mmEndAddr
    cdef char *mmAreaData
    cdef void mmResetAreaData(self)
    cpdef mmFreeAreaData(self)
    cdef void mmSetReadOnly(self, unsigned char mmReadOnly)
    cdef bytes mmAreaRead(self, unsigned int mmAddr, unsigned int dataSize)
    cdef void mmAreaWrite(self, unsigned int mmAddr, char *data, unsigned int dataSize)
    cdef void mmAreaCopy(self, unsigned int destAddr, unsigned int srcAddr, unsigned int dataSize)
    cpdef run(self)


cdef class Mm:
    cpdef object main
    cdef list mmAreas
    cdef void mmAddArea(self, unsigned int mmBaseAddr, unsigned int mmAreaSize, unsigned char mmReadOnly, MmArea mmAreaObject)
    cdef unsigned char mmDelArea(self, unsigned int mmBaseAddr)
    cdef MmArea mmGetSingleArea(self, unsigned int mmAddr, unsigned int dataSize)
    cdef list mmGetAreas(self, unsigned int mmAddr, unsigned int dataSize)
    cpdef object mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize)
    cpdef object mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize)
    cpdef object mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize)
    cpdef object mmPhyWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize)
    cpdef object mmPhyWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize)
    cpdef object mmPhyCopy(self, unsigned int destAddr, unsigned int srcAddr, unsigned int dataSize)

cdef class ConfigSpace:
    cpdef object main
    cdef char *csData
    cdef unsigned int csSize
    cdef void csResetData(self)
    cpdef csFreeData(self)
    cdef bytes csRead(self, unsigned int offset, unsigned int size)
    cdef void csWrite(self, unsigned int offset, bytes data, unsigned int size)
    cdef void csCopy(self, unsigned int destOffset, unsigned int srcOffset, unsigned int size)
    cdef unsigned long int csReadValueUnsigned(self, unsigned int offset, unsigned char size)
    cdef unsigned long int csReadValueUnsignedBE(self, unsigned int offset, unsigned char size)
    cdef long int csReadValueSigned(self, unsigned int offset, unsigned char size)
    cdef long int csReadValueSignedBE(self, unsigned int offset, unsigned char size)
    cdef unsigned long int csWriteValue(self, unsigned int offset, unsigned long int data, unsigned char size)
    cdef unsigned long int csWriteValueBE(self, unsigned int offset, unsigned long int data, unsigned char size)
    cdef unsigned long int csAddValue(self, unsigned int offset, unsigned long int data, unsigned char size)
    cdef unsigned long int csSubValue(self, unsigned int offset, unsigned long int data, unsigned char size)
    cpdef run(self)







