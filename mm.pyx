
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"
include "cpu_globals.pxi"

from traceback import print_exc
from atexit import register


cdef class Mm:
    def __init__(self, Hirnwichse main):
        cdef unsigned short i
        self.main = main
        self.ignoreRomWrite = False
        self.memSizeBytes = self.main.memSize*1024*1024
        self.data = self.pciData = self.romData = self.tempData = NULL
        with nogil:
            self.data = <char*>malloc(self.memSizeBytes)
            self.pciData = <char*>malloc(SIZE_1MB)
            self.romData = <char*>malloc(SIZE_1MB)
            self.tempData = <char*>malloc(SIZE_4KB)
        if (self.data is NULL or self.pciData is NULL or self.romData is NULL or self.tempData is NULL):
            self.main.exitError("Mm::init: not self.data or not self.pciData or not self.romData or not self.tempData.")
            return
        with nogil:
            memset(self.data, 0, self.memSizeBytes)
            memset(self.pciData, 0, SIZE_1MB)
            memset(self.romData, 0, SIZE_1MB)
            memset(self.tempData, 0, SIZE_4KB)
        register(self.quitFunc)
    cpdef quitFunc(self):
        try:
            self.main.quitFunc()
            if (self.data is not NULL):
                free(self.data)
                self.data = NULL
            if (self.pciData is not NULL):
                free(self.pciData)
                self.pciData = NULL
            if (self.romData is not NULL):
                free(self.romData)
                self.romData = NULL
            if (self.tempData is not NULL):
                free(self.tempData)
                self.tempData = NULL
        except:
            print_exc()
            self.main.exitError('Mm::quitFunc: exception, exiting...')
    cdef void mmClear(self, unsigned int offset, unsigned char clearByte, unsigned int dataSize) nogil:
        with nogil:
            memset(<char*>(self.data+offset), clearByte, dataSize)
    cdef char *mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize) nogil:
        cdef unsigned int tempDataOffset = 0, tempOffset, tempSize
        if (dataSize > 0 and mmAddr < VGA_MEMAREA_ADDR):
            tempSize = min(dataSize, VGA_MEMAREA_ADDR-mmAddr)
            memcpy(self.mmGetTempDataPointer(tempDataOffset), self.mmGetDataPointer(mmAddr), tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= VGA_MEMAREA_ADDR and mmAddr < VGA_ROM_BASE):
            tempSize = min(dataSize, VGA_ROM_BASE-mmAddr)
            with gil:
                memcpy(self.mmGetTempDataPointer(tempDataOffset), self.main.platform.vga.vgaAreaRead(mmAddr, tempSize), tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= VGA_ROM_BASE and mmAddr < self.memSizeBytes):
            tempSize = min(dataSize, self.memSizeBytes-mmAddr)
            memcpy(self.mmGetTempDataPointer(tempDataOffset), self.mmGetDataPointer(mmAddr), tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= self.memSizeBytes and mmAddr < PCI_MEM_BASE):
            tempSize = min(dataSize, PCI_MEM_BASE-mmAddr)
            #self.main.notice("Mm::mmPhyRead: filling1; mmAddr=={0:#010x}; tempSize=={1:d}", mmAddr, tempSize)
            memset(self.mmGetTempDataPointer(tempDataOffset), 0xff, tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE and mmAddr < PCI_MEM_BASE_PLUS_LIMIT):
            tempOffset = mmAddr-PCI_MEM_BASE
            tempSize = min(dataSize, PCI_MEM_BASE_PLUS_LIMIT-mmAddr)
            memcpy(self.mmGetTempDataPointer(tempDataOffset), self.mmGetPciDataPointer(mmAddr), tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE_PLUS_LIMIT and mmAddr < LAST_MEMAREA_BASE_ADDR):
            tempSize = min(dataSize, LAST_MEMAREA_BASE_ADDR-mmAddr)
            #self.main.notice("Mm::mmPhyRead: filling2; mmAddr=={0:#010x}; tempSize=={1:d}", mmAddr, tempSize)
            memset(self.mmGetTempDataPointer(tempDataOffset), 0xff, tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= LAST_MEMAREA_BASE_ADDR and mmAddr < SIZE_4GB):
            tempOffset = mmAddr-LAST_MEMAREA_BASE_ADDR
            tempSize = min(dataSize, SIZE_4GB-mmAddr)
            memcpy(self.mmGetTempDataPointer(tempDataOffset), self.mmGetRomDataPointer(mmAddr), tempSize)
        return self.tempData
    cdef signed long int mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize) nogil except? BITMASK_BYTE_CONST:
        cdef signed long int ret
        ret = self.mmPhyReadValueUnsigned(mmAddr, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            ret = <signed char>ret
        elif (dataSize == OP_SIZE_WORD):
            ret = <signed short>ret
        elif (dataSize == OP_SIZE_DWORD):
            ret = <signed int>ret
        return ret
    cdef unsigned char mmPhyReadValueUnsignedByte(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_BYTE or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_BYTE)):
            return (<unsigned char*>self.mmGetDataPointer(mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_BYTE)
    cdef unsigned short mmPhyReadValueUnsignedWord(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_WORD or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_WORD)):
            return (<unsigned short*>self.mmGetDataPointer(mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_WORD)
    cdef unsigned int mmPhyReadValueUnsignedDword(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_DWORD or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_DWORD)):
            return (<unsigned int*>self.mmGetDataPointer(mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_DWORD)
    cdef unsigned long int mmPhyReadValueUnsignedQword(self, unsigned int mmAddr) nogil except? BITMASK_BYTE_CONST:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_QWORD or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_QWORD)):
            return (<unsigned long int*>self.mmGetDataPointer(mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_QWORD)
    cdef unsigned long int mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize) nogil except? BITMASK_BYTE_CONST:
        cdef char *temp
        if (mmAddr <= VGA_MEMAREA_ADDR-dataSize or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-dataSize)):
            temp = self.mmGetDataPointer(mmAddr)
        else:
            temp = self.mmPhyRead(mmAddr, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            return (<unsigned char*>temp)[0]
        elif (dataSize == OP_SIZE_WORD):
            return (<unsigned short*>temp)[0]
        elif (dataSize == OP_SIZE_DWORD):
            return (<unsigned int*>temp)[0]
        return (<unsigned long int*>temp)[0]
    cdef unsigned char mmPhyWrite(self, unsigned int mmAddr, char *data, unsigned int dataSize) nogil except BITMASK_BYTE_CONST:
        cdef unsigned int tempOffset, tempSize
        if (dataSize > 0 and mmAddr < SIZE_1MB):
            if (mmAddr < VGA_MEMAREA_ADDR):
                tempSize = min(dataSize, VGA_MEMAREA_ADDR-mmAddr)
                with nogil:
                    memcpy(<char*>(self.data+mmAddr), data, tempSize)
                if (dataSize <= tempSize):
                    return True
                dataSize -= tempSize
                mmAddr += tempSize
                data += tempSize
            if (dataSize > 0 and mmAddr >= VGA_MEMAREA_ADDR and mmAddr < VGA_ROM_BASE):
                tempSize = min(dataSize, VGA_ROM_BASE-mmAddr)
                with nogil:
                    memcpy(<char*>(self.data+mmAddr), data, tempSize)
                self.main.platform.vga.vgaAreaWrite(mmAddr, tempSize)
                if (dataSize <= tempSize):
                    return True
                dataSize -= tempSize
                mmAddr += tempSize
                data += tempSize
            if (dataSize > 0 and mmAddr >= VGA_ROM_BASE and mmAddr < SIZE_1MB):
                tempSize = min(dataSize, SIZE_1MB-mmAddr)
                if (not self.ignoreRomWrite):
                    with nogil:
                        memcpy(<char*>(self.data+mmAddr), data, tempSize)
                if (dataSize <= tempSize):
                    return True
                dataSize -= tempSize
                mmAddr += tempSize
                data += tempSize
        if (dataSize > 0 and mmAddr >= SIZE_1MB and mmAddr < self.memSizeBytes):
            tempSize = min(dataSize, self.memSizeBytes-mmAddr)
            with nogil:
                memcpy(<char*>(self.data+mmAddr), data, tempSize)
            if (dataSize <= tempSize):
                return True
            dataSize -= tempSize
            mmAddr += tempSize
            data += tempSize
        if (dataSize > 0 and mmAddr >= self.memSizeBytes and mmAddr < PCI_MEM_BASE):
            tempSize = min(dataSize, PCI_MEM_BASE-mmAddr)
            #self.main.notice("Mm::mmPhyWrite: filling1; mmAddr=={0:#010x}; tempSize=={1:d}", mmAddr, tempSize)
            if (dataSize <= tempSize):
                return True
            dataSize -= tempSize
            mmAddr += tempSize
            data += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE and mmAddr < PCI_MEM_BASE_PLUS_LIMIT):
            tempOffset = mmAddr-PCI_MEM_BASE
            tempSize = min(dataSize, PCI_MEM_BASE_PLUS_LIMIT-mmAddr)
            with nogil:
                memcpy(<char*>(self.pciData+tempOffset), data, tempSize)
            if (dataSize <= tempSize):
                return True
            dataSize -= tempSize
            mmAddr += tempSize
            data += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE_PLUS_LIMIT and mmAddr < LAST_MEMAREA_BASE_ADDR):
            tempSize = min(dataSize, LAST_MEMAREA_BASE_ADDR-mmAddr)
            #self.main.notice("Mm::mmPhyWrite: filling2; mmAddr=={0:#010x}; tempSize=={1:d}", mmAddr, tempSize)
            if (dataSize <= tempSize):
                return True
            dataSize -= tempSize
            mmAddr += tempSize
            data += tempSize
        if (not self.ignoreRomWrite):
            if (dataSize > 0 and mmAddr >= LAST_MEMAREA_BASE_ADDR and mmAddr < SIZE_4GB):
                tempOffset = mmAddr-LAST_MEMAREA_BASE_ADDR
                tempSize = min(dataSize, SIZE_4GB-mmAddr)
                with nogil:
                    memcpy(<char*>(self.romData+tempOffset), data, tempSize)
        return True
    cdef unsigned char mmPhyWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize) nogil except BITMASK_BYTE_CONST:
        cdef char *temp
        if (dataSize == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (dataSize == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (dataSize == OP_SIZE_DWORD):
            data = <unsigned int>data
        #elif (dataSize != OP_SIZE_QWORD):
        #    return self.mmPhyWrite(mmAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
        temp = <char*>&data
        return self.mmPhyWrite(mmAddr, temp, dataSize)


cdef class ConfigSpace:
    def __init__(self, unsigned int csSize, Hirnwichse main):
        self.csSize = csSize
        self.main = main
        self.csData = <char*>malloc(self.csSize)
        if (not self.csData):
            self.main.exitError("ConfigSpace::run: not self.csData.")
            return
        self.csResetData(0)
        register(self.quitFunc)
    cpdef quitFunc(self):
        try:
            self.main.quitFunc()
            if (self.csData is not NULL):
                free(self.csData)
                self.csData = NULL
        except:
            print_exc()
            self.main.exitError('ConfigSpace::quitFunc: exception, exiting...')
    cdef void csResetData(self, unsigned char clearByte) nogil:
        self.clearByte = clearByte
        with nogil:
            memset(self.csData, clearByte, self.csSize)
    cdef void csResetAddr(self, unsigned int offset, unsigned char clearByte, unsigned char size) nogil:
        with nogil:
            memset(<char*>(self.csData+offset), clearByte, size)
    cdef bytes csRead(self, unsigned int offset, unsigned int size):
        cdef bytes data
        cdef unsigned int tempSize
        tempSize = min(size, self.csSize-offset)
        data = self.csData[offset:offset+tempSize]
        size -= tempSize
        if (size > 0):
            if (self.main.debugEnabled):
                self.main.debug("ConfigSpace::csRead: offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
            data += bytes([self.clearByte])*size
        return data
    cdef void csWrite(self, unsigned int offset, char *data, unsigned int size) nogil:
        cdef unsigned int tempSize
        tempSize = min(size, self.csSize-offset)
        with nogil:
            memcpy(<char*>(self.csData+offset), <char*>data, tempSize)
        size -= tempSize
        #if (size > 0 and self.main.debugEnabled):
        #    self.main.debug("ConfigSpace::csWrite: offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
    cdef unsigned long int csReadValueUnsigned(self, unsigned int offset, unsigned char size) nogil except? BITMASK_BYTE_CONST:
        cdef unsigned long int ret
        #if (self.main.debugEnabled):
        #    self.main.debug("ConfigSpace::csReadValueUnsigned: test1. (offset: {0:#06x}, size: {1:d})", offset, size)
        ret = (<unsigned long int*>self.csGetDataPointer(offset))[0]
        if (size == OP_SIZE_BYTE):
            ret = <unsigned char>ret
        elif (size == OP_SIZE_WORD):
            ret = <unsigned short>ret
        elif (size == OP_SIZE_DWORD):
            ret = <unsigned int>ret
        return ret
    cdef signed long int csReadValueSigned(self, unsigned int offset, unsigned char size) nogil except? BITMASK_BYTE_CONST:
        cdef signed long int ret
        #if (self.main.debugEnabled):
        #    self.main.debug("ConfigSpace::csReadValueSigned: test1. (offset: {0:#06x}, size: {1:d})", offset, size)
        ret = (<signed long int*>self.csGetDataPointer(offset))[0]
        if (size == OP_SIZE_BYTE):
            ret = <signed char>ret
        elif (size == OP_SIZE_WORD):
            ret = <signed short>ret
        elif (size == OP_SIZE_DWORD):
            ret = <signed int>ret
        return ret
    cdef unsigned long int csWriteValue(self, unsigned int offset, unsigned long int data, unsigned char size) nogil except? BITMASK_BYTE_CONST:
        cdef char *temp
        if (size == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (size == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (size == OP_SIZE_DWORD):
            data = <unsigned int>data
        #elif (size != OP_SIZE_QWORD):
        #    self.csWrite(offset, data.to_bytes(length=size, byteorder="little", signed=False), size)
        #    return data
        #if (self.main.debugEnabled):
        #    self.main.debug("ConfigSpace::csWriteValue: test1. (offset: {0:#06x}, data: {1:#04x}, size: {2:d})", offset, data, size)
        temp = <char*>&data
        self.csWrite(offset, temp, size)
        return data


