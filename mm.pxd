
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
    cdef char *vgaRomData
    cdef uint8_t ignoreRomWrite
    cdef uint64_t memSizeBytes
    cdef void quitFunc(self)
    cdef void mmClear(self, uint32_t mmAddr, uint8_t clearByte, uint32_t dataSize)
    cdef char *mmPhyRead(self, uint32_t mmAddr, uint32_t dataSize)
    cdef int64_t mmPhyReadValueSigned(self, uint32_t mmAddr, uint8_t dataSize)
    cdef uint8_t mmPhyReadValueUnsignedByte(self, uint32_t mmAddr)
    cdef uint16_t mmPhyReadValueUnsignedWord(self, uint32_t mmAddr)
    cdef uint32_t mmPhyReadValueUnsignedDword(self, uint32_t mmAddr)
    cdef uint64_t mmPhyReadValueUnsignedQword(self, uint32_t mmAddr)
    cdef uint64_t mmPhyReadValueUnsigned(self, uint32_t mmAddr, uint8_t dataSize)
    cdef uint8_t mmPhyWrite(self, uint32_t mmAddr, char *data, uint32_t dataSize)
    cdef uint8_t mmPhyWriteValue(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize)

cdef class ConfigSpace:
    cdef Hirnwichse main
    cdef char *csData
    cdef uint8_t clearByte
    cdef uint32_t csSize
    cdef void quitFunc(self)
    cdef void csResetData(self, uint8_t clearByte)
    cdef void csResetAddr(self, uint32_t offset, uint8_t clearByte, uint8_t size)
    cdef bytes csRead(self, uint32_t offset, uint32_t size)
    cdef void csWrite(self, uint32_t offset, char *data, uint32_t size)
    cdef uint8_t csReadValueUnsignedByte(self, uint32_t offset)
    cdef uint16_t csReadValueUnsignedWord(self, uint32_t offset)
    cdef uint32_t csReadValueUnsignedDword(self, uint32_t offset)
    cdef uint64_t csReadValueUnsigned(self, uint32_t offset, uint8_t size)
    cdef int64_t csReadValueSigned(self, uint32_t offset, uint8_t size)
    cdef void csWriteValueByte(self, uint32_t offset, uint8_t data)
    cdef void csWriteValueWord(self, uint32_t offset, uint16_t data)
    cdef void csWriteValueDword(self, uint32_t offset, uint32_t data)
    cdef void csWriteValueQword(self, uint32_t offset, uint64_t data)
    cdef void csWriteValue(self, uint32_t offset, uint64_t data, uint8_t size)


