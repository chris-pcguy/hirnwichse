
include "globals.pxi"

from libc.stdlib cimport malloc, free
from libc.string cimport memcpy, memset


from hirnwichse_main cimport Hirnwichse

cdef class Mm:
    cdef Hirnwichse main
    cdef char *data
    cdef char *pciData
    cdef char *romData
    cdef public unsigned char ignoreRomWrite
    cdef unsigned long int memSizeBytes
    cpdef quitFunc(self)
    cdef inline char *mmGetDataPointer(self, unsigned int mmAddr) nogil:
        return <char*>(self.data+mmAddr)
    cdef void mmClear(self, unsigned long int mmAddr, unsigned char clearByte, unsigned long int dataSize) nogil
    cdef bytes mmPhyRead(self, unsigned long int mmAddr, unsigned long int dataSize)
    cdef inline signed char mmPhyReadValueSignedByte(self, unsigned long int mmAddr) except? BITMASK_BYTE:
        return <signed char>self.mmPhyReadValueUnsignedByte(mmAddr)
    cdef inline signed short mmPhyReadValueSignedWord(self, unsigned long int mmAddr) except? BITMASK_BYTE:
        return <signed short>self.mmPhyReadValueUnsignedWord(mmAddr)
    cdef inline signed int mmPhyReadValueSignedDword(self, unsigned long int mmAddr) except? BITMASK_BYTE:
        return <signed int>self.mmPhyReadValueUnsignedDword(mmAddr)
    cdef inline signed long int mmPhyReadValueSignedQword(self, unsigned long int mmAddr) except? BITMASK_BYTE:
        return <signed long int>self.mmPhyReadValueUnsignedQword(mmAddr)
    cdef signed long int mmPhyReadValueSigned(self, unsigned long int mmAddr, unsigned char dataSize) except? BITMASK_BYTE
    cdef unsigned char mmPhyReadValueUnsignedByte(self, unsigned long int mmAddr) except? BITMASK_BYTE
    cdef unsigned short mmPhyReadValueUnsignedWord(self, unsigned long int mmAddr) except? BITMASK_BYTE
    cdef unsigned int mmPhyReadValueUnsignedDword(self, unsigned long int mmAddr) except? BITMASK_BYTE
    cdef unsigned long int mmPhyReadValueUnsignedQword(self, unsigned long int mmAddr) except? BITMASK_BYTE
    cdef unsigned long int mmPhyReadValueUnsigned(self, unsigned long int mmAddr, unsigned char dataSize) except? BITMASK_BYTE
    cdef unsigned char mmPhyWrite(self, unsigned long int mmAddr, char *data, unsigned long int dataSize) except BITMASK_BYTE
    cdef unsigned char mmPhyWriteValue(self, unsigned long int mmAddr, unsigned long int data, unsigned char dataSize) except BITMASK_BYTE
    cdef void mmPhyCopy(self, unsigned long int destAddr, unsigned long int srcAddr, unsigned long int dataSize)

cdef class ConfigSpace:
    cdef Hirnwichse main
    cdef char *csData
    cdef unsigned char clearByte
    cdef unsigned int csSize
    cpdef quitFunc(self)
    cdef void csResetData(self, unsigned char clearByte) nogil
    cdef inline char *csGetDataPointer(self, unsigned int offset) nogil:
        return <char*>(self.csData+offset)
    cdef bytes csRead(self, unsigned int offset, unsigned int size)
    cdef void csWrite(self, unsigned int offset, char *data, unsigned int size)
    cdef unsigned long int csReadValueUnsigned(self, unsigned int offset, unsigned char size) nogil except? BITMASK_BYTE
    cdef signed long int csReadValueSigned(self, unsigned int offset, unsigned char size) nogil except? BITMASK_BYTE
    cdef unsigned long int csWriteValue(self, unsigned int offset, unsigned long int data, unsigned char size) except? BITMASK_BYTE


