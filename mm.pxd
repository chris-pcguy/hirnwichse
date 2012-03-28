
from misc cimport Misc
from libc.stdlib cimport calloc, malloc, free
from libc.string cimport strncpy, memcpy, memset, memmove

DEF MM_NUMAREAS = 4096

ctypedef bytes (*MmAreaReadType)(self, MmArea, unsigned int, unsigned int)
ctypedef void (*MmAreaWriteType)(self, MmArea, unsigned int, char *, unsigned int)

cdef class MmArea:
    cdef unsigned char readOnly
    cdef unsigned int start, end
    cdef char *data
    cdef object readClass
    cdef MmAreaReadType readHandler
    cdef object writeClass
    cdef MmAreaWriteType writeHandler


cdef class Mm:
    cpdef object main
    cdef list mmAreas
    cdef MmArea mmAddArea(self, unsigned int mmBaseAddr, unsigned char mmReadOnly)
    cdef unsigned char mmDelArea(self, unsigned int mmAddr)
    cdef MmArea mmGetArea(self, unsigned int mmAddr)
    cdef list mmGetAreas(self, unsigned int mmAddr, unsigned int dataSize)
    cdef void mmSetReadOnly(self, unsigned int mmAddr, unsigned char mmReadOnly)
    cdef bytes mmAreaRead(self, MmArea mmArea, unsigned int offset, unsigned int dataSize)
    cdef void mmAreaWrite(self, MmArea mmArea, unsigned int offset, char *data, unsigned int dataSize)
    cpdef object mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize)
    cpdef object mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize)
    cpdef object mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize)
    cpdef object mmPhyWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize)
    cpdef object mmPhyWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize)
    cpdef object mmPhyCopy(self, unsigned int destAddr, unsigned int srcAddr, unsigned int dataSize)
    cpdef run(self)

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







