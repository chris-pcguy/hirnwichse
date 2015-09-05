
include "globals.pxi"

from libc.stdlib cimport malloc, free
from libc.string cimport memcpy, memset


from hirnwichse_main cimport Hirnwichse

cdef class Mm:
    cdef Hirnwichse main
    cdef char *data
    cdef char *pciData
    cdef char *romData
    cdef char *tempData
    cdef unsigned char ignoreRomWrite
    cdef unsigned long int memSizeBytes
    cpdef quitFunc(self)
    cdef inline char *mmGetDataPointer(self, unsigned int mmAddr) nogil:
        return <char*>(self.data+mmAddr)
    cdef inline char *mmGetPciDataPointer(self, unsigned int mmAddr) nogil:
        return <char*>(self.pciData+mmAddr)
    cdef inline char *mmGetRomDataPointer(self, unsigned int mmAddr) nogil:
        return <char*>(self.romData+mmAddr)
    cdef inline char *mmGetTempDataPointer(self, unsigned int mmAddr) nogil:
        return <char*>(self.tempData+mmAddr)
    cdef void mmClear(self, unsigned int mmAddr, unsigned char clearByte, unsigned int dataSize) nogil
    cdef char *mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize) nogil
    cdef inline signed short mmPhyReadValueSignedByte(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST:
        return <signed char>self.mmPhyReadValueUnsignedByte(mmAddr)
    cdef inline signed short mmPhyReadValueSignedWord(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST:
        return <signed short>self.mmPhyReadValueUnsignedWord(mmAddr)
    cdef inline signed int mmPhyReadValueSignedDword(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST:
        return <signed int>self.mmPhyReadValueUnsignedDword(mmAddr)
    cdef inline signed long int mmPhyReadValueSignedQword(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST:
        return <signed long int>self.mmPhyReadValueUnsignedQword(mmAddr)
    cdef signed long int mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize) nogil except? BITMASK_BYTE_CONST
    cdef unsigned char mmPhyReadValueUnsignedByte(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST
    cdef unsigned short mmPhyReadValueUnsignedWord(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST
    cdef unsigned int mmPhyReadValueUnsignedDword(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST
    cdef unsigned long int mmPhyReadValueUnsignedQword(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST
    cdef unsigned long int mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize) nogil except? BITMASK_BYTE_CONST
    cdef unsigned char mmPhyWrite(self, unsigned int mmAddr, char *data, unsigned int dataSize) nogil except BITMASK_BYTE_CONST
    cdef unsigned char mmPhyWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize) nogil except BITMASK_BYTE_CONST

cdef class ConfigSpace:
    cdef Hirnwichse main
    cdef char *csData
    cdef unsigned char clearByte
    cdef unsigned int csSize
    cpdef quitFunc(self)
    cdef void csResetData(self, unsigned char clearByte) nogil
    cdef void csResetAddr(self, unsigned int offset, unsigned char clearByte, unsigned char size) nogil
    cdef inline char *csGetDataPointer(self, unsigned int offset) nogil:
        return <char*>(self.csData+offset)
    cdef bytes csRead(self, unsigned int offset, unsigned int size)
    cdef void csWrite(self, unsigned int offset, char *data, unsigned int size) nogil
    cdef unsigned long int csReadValueUnsigned(self, unsigned int offset, unsigned char size) nogil except? BITMASK_BYTE_CONST
    cdef signed long int csReadValueSigned(self, unsigned int offset, unsigned char size) nogil except? BITMASK_BYTE_CONST
    cdef unsigned long int csWriteValue(self, unsigned int offset, unsigned long int data, unsigned char size) nogil except? BITMASK_BYTE_CONST


