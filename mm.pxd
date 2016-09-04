
include "globals.pxi"

from libc.stdint cimport *
from libc.stdlib cimport malloc, free, exit as exitt
from libc.string cimport memcpy, memset


from hirnwichse_main cimport Hirnwichse

cdef class Mm:
    cdef Hirnwichse main
    cdef char *data
    cdef char *pciData
    cdef char *romData
    cdef char *tempData
    cdef uint8_t ignoreRomWrite
    cdef uint64_t memSizeBytes
    cpdef quitFunc(self)
    cdef void mmClear(self, uint32_t mmAddr, uint8_t clearByte, uint32_t dataSize) nogil
    cdef char *mmPhyRead(self, uint32_t mmAddr, uint32_t dataSize) nogil
    cdef inline int16_t mmPhyReadValueSignedByte(self, uint32_t mmAddr) nogil except? BITMASK_BYTE_CONST:
        return <int8_t>self.mmPhyReadValueUnsignedByte(mmAddr)
    cdef inline int16_t mmPhyReadValueSignedWord(self, uint32_t mmAddr) nogil except? BITMASK_BYTE_CONST:
        return <int16_t>self.mmPhyReadValueUnsignedWord(mmAddr)
    cdef inline int32_t mmPhyReadValueSignedDword(self, uint32_t mmAddr) nogil except? BITMASK_BYTE_CONST:
        return <int32_t>self.mmPhyReadValueUnsignedDword(mmAddr)
    cdef inline int64_t mmPhyReadValueSignedQword(self, uint32_t mmAddr) nogil except? BITMASK_BYTE_CONST:
        return <int64_t>self.mmPhyReadValueUnsignedQword(mmAddr)
    cdef int64_t mmPhyReadValueSigned(self, uint32_t mmAddr, uint8_t dataSize) nogil except? BITMASK_BYTE_CONST
    cdef uint8_t mmPhyReadValueUnsignedByte(self, uint32_t mmAddr) nogil except? BITMASK_BYTE_CONST
    cdef uint16_t mmPhyReadValueUnsignedWord(self, uint32_t mmAddr) nogil except? BITMASK_BYTE_CONST
    cdef uint32_t mmPhyReadValueUnsignedDword(self, uint32_t mmAddr) nogil except? BITMASK_BYTE_CONST
    cdef uint64_t mmPhyReadValueUnsignedQword(self, uint32_t mmAddr) nogil except? BITMASK_BYTE_CONST
    cdef uint64_t mmPhyReadValueUnsigned(self, uint32_t mmAddr, uint8_t dataSize) nogil except? BITMASK_BYTE_CONST
    cdef uint8_t mmPhyWrite(self, uint32_t mmAddr, char *data, uint32_t dataSize) nogil except BITMASK_BYTE_CONST
    cdef uint8_t mmPhyWriteValue(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize) nogil except BITMASK_BYTE_CONST

cdef class ConfigSpace:
    cdef Hirnwichse main
    cdef char *csData
    cdef uint8_t clearByte
    cdef uint32_t csSize
    cpdef quitFunc(self)
    cdef void csResetData(self, uint8_t clearByte) nogil
    cdef void csResetAddr(self, uint32_t offset, uint8_t clearByte, uint8_t size) nogil
    cdef bytes csRead(self, uint32_t offset, uint32_t size)
    cdef void csWrite(self, uint32_t offset, char *data, uint32_t size) nogil
    cdef uint64_t csReadValueUnsigned(self, uint32_t offset, uint8_t size) nogil except? BITMASK_BYTE_CONST
    cdef int64_t csReadValueSigned(self, uint32_t offset, uint8_t size) nogil except? BITMASK_BYTE_CONST
    cdef uint64_t csWriteValue(self, uint32_t offset, uint64_t data, uint8_t size) nogil except? BITMASK_BYTE_CONST


