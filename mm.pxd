
include "globals.pxi"

from libc.stdlib cimport malloc
from libc.string cimport memcpy, memset


ctypedef bytes (*MmAreaReadType)(self, MmArea, unsigned int, unsigned int)
ctypedef void (*MmAreaWriteType)(self, MmArea, unsigned int, char *, unsigned int)

ctypedef struct MmArea:
    unsigned char readOnly, valid
    unsigned short mmIndex
    MmAreaReadType readHandler
    MmAreaWriteType writeHandler
    char *data

from hirnwichse_main cimport Hirnwichse

cdef class Mm:
    cdef Hirnwichse main
    cdef MmArea mmAreas[MM_NUMAREAS]
    cdef void mmAddArea(self, unsigned short mmIndex, unsigned char mmReadOnly)
    cdef void mmGetAreasCount(self, unsigned int mmAddr, unsigned int dataSize, unsigned short *begin, unsigned short *end)
    cdef void mmSetReadOnly(self, unsigned short mmIndex, unsigned char mmReadOnly)
    cdef inline char *mmGetDataPointer(self, MmArea mmArea, unsigned int offset):
        return <char*>(mmArea.data+offset)
    cdef bytes mmAreaRead(self, MmArea mmArea, unsigned int offset, unsigned int dataSize)
    cdef void mmAreaWrite(self, MmArea mmArea, unsigned int offset, char *data, unsigned int dataSize)
    cdef void mmAreaClear(self, MmArea mmArea, unsigned int offset, unsigned char clearByte, unsigned int dataSize)
    cdef bytes mmAreaReadSystem(self, MmArea mmArea, unsigned int offset, unsigned int dataSize)
    cdef void mmAreaWriteSystem(self, MmArea mmArea, unsigned int offset, char *data, unsigned int dataSize)
    cdef bytes mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize)
    cdef inline signed char mmPhyReadValueSignedByte(self, unsigned int mmAddr) except? BITMASK_BYTE:
        return <signed char>self.mmPhyReadValueUnsignedByte(mmAddr)
    cdef inline signed short mmPhyReadValueSignedWord(self, unsigned int mmAddr) except? BITMASK_BYTE:
        return <signed short>self.mmPhyReadValueUnsignedWord(mmAddr)
    cdef inline signed int mmPhyReadValueSignedDword(self, unsigned int mmAddr) except? BITMASK_BYTE:
        return <signed int>self.mmPhyReadValueUnsignedDword(mmAddr)
    cdef inline signed long int mmPhyReadValueSignedQword(self, unsigned int mmAddr) except? BITMASK_BYTE:
        return <signed long int>self.mmPhyReadValueUnsignedQword(mmAddr)
    cdef signed long int mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize) except? BITMASK_BYTE
    cdef unsigned char mmPhyReadValueUnsignedByte(self, unsigned int mmAddr) except? BITMASK_BYTE
    cdef unsigned short mmPhyReadValueUnsignedWord(self, unsigned int mmAddr) except? BITMASK_BYTE
    cdef unsigned int mmPhyReadValueUnsignedDword(self, unsigned int mmAddr) except? BITMASK_BYTE
    cdef unsigned long int mmPhyReadValueUnsignedQword(self, unsigned int mmAddr) except? BITMASK_BYTE
    cdef unsigned long int mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize) except? BITMASK_BYTE
    cdef unsigned char mmPhyWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize) except BITMASK_BYTE
    cdef unsigned char mmPhyWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize) except BITMASK_BYTE
    cdef void mmPhyCopy(self, unsigned int destAddr, unsigned int srcAddr, unsigned int dataSize)

cdef class ConfigSpace:
    cdef Hirnwichse main
    cdef char *csData
    cdef unsigned char clearByte
    cdef unsigned int csSize
    cdef void csResetData(self, unsigned char clearByte = ?)
    cdef bytes csRead(self, unsigned int offset, unsigned int size)
    cdef void csWrite(self, unsigned int offset, char *data, unsigned int size)
    cdef unsigned long int csReadValueUnsigned(self, unsigned int offset, unsigned char size) except? BITMASK_BYTE
    cdef unsigned long int csReadValueUnsignedBE(self, unsigned int offset, unsigned char size) except? BITMASK_BYTE
    cdef signed long int csReadValueSigned(self, unsigned int offset, unsigned char size) except? BITMASK_BYTE
    cdef signed long int csReadValueSignedBE(self, unsigned int offset, unsigned char size) except? BITMASK_BYTE
    cdef unsigned long int csWriteValue(self, unsigned int offset, unsigned long int data, unsigned char size) except? BITMASK_BYTE
    cdef unsigned long int csWriteValueBE(self, unsigned int offset, unsigned long int data, unsigned char size) except? BITMASK_BYTE







