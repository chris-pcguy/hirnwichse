
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"
include "cpu_globals.pxi"

from atexit import register


cdef class Mm:
    def __init__(self, Hirnwichse main):
        cdef unsigned short i
        self.main = main
        self.ignoreRomWrite = False
        self.memSizeBytes = self.main.memSize*1024*1024
        self.data = self.pciData = self.romData = NULL
        with nogil:
            self.data = <char*>malloc(self.memSizeBytes)
            self.pciData = <char*>malloc(SIZE_1MB)
            self.romData = <char*>malloc(SIZE_1MB)
        if (self.data is NULL or self.pciData is NULL or self.romData is NULL):
            self.main.exitError("Mm::init: not self.data or not self.pciData or not self.romData.")
            return
        with nogil:
            memset(self.data, 0, self.memSizeBytes)
            memset(self.pciData, 0, SIZE_1MB)
            memset(self.romData, 0, SIZE_1MB)
    cdef void mmClear(self, unsigned long int offset, unsigned char clearByte, unsigned long int dataSize):
        with nogil:
            memset(<char*>(self.data+offset), clearByte, dataSize)
    cdef bytes mmPhyRead(self, unsigned long int mmAddr, unsigned long int dataSize):
        cdef unsigned long int tempOffset, tempSize
        cdef bytes ret = bytes()
        if (dataSize > 0 and mmAddr < VGA_MEMAREA_ADDR):
            tempSize = min(dataSize, VGA_MEMAREA_ADDR-mmAddr)
            ret += self.data[mmAddr:mmAddr+tempSize]
            if (dataSize <= tempSize):
                return ret
            dataSize -= tempSize
            mmAddr += tempSize
        if (dataSize > 0 and mmAddr >= VGA_MEMAREA_ADDR and mmAddr < VGA_ROM_BASE):
            tempSize = min(dataSize, VGA_ROM_BASE-mmAddr)
            ret += self.main.platform.vga.vgaAreaRead(mmAddr, tempSize)
            if (dataSize <= tempSize):
                return ret
            dataSize -= tempSize
            mmAddr += tempSize
        if (dataSize > 0 and mmAddr >= VGA_ROM_BASE and mmAddr < self.memSizeBytes):
            tempSize = min(dataSize, self.memSizeBytes-mmAddr)
            ret += self.data[mmAddr:mmAddr+tempSize]
            if (dataSize <= tempSize):
                return ret
            dataSize -= tempSize
            mmAddr += tempSize
        if (dataSize > 0 and mmAddr >= self.memSizeBytes and mmAddr < PCI_MEM_BASE):
            tempSize = min(dataSize, PCI_MEM_BASE-mmAddr)
            self.main.notice("Mm::mmPhyRead: filling1; mmAddr=={0:#010x}; tempSize=={1:d}", mmAddr, tempSize)
            ret += b"\xff"*tempSize
            if (dataSize <= tempSize):
                return ret
            dataSize -= tempSize
            mmAddr += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE and mmAddr < PCI_MEM_BASE_PLUS_LIMIT):
            tempOffset = mmAddr-PCI_MEM_BASE
            tempSize = min(dataSize, PCI_MEM_BASE_PLUS_LIMIT-mmAddr)
            ret += self.pciData[tempOffset:tempOffset+tempSize]
            if (dataSize <= tempSize):
                return ret
            dataSize -= tempSize
            mmAddr += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE_PLUS_LIMIT and mmAddr < LAST_MEMAREA_BASE_ADDR):
            tempSize = min(dataSize, LAST_MEMAREA_BASE_ADDR-mmAddr)
            self.main.notice("Mm::mmPhyRead: filling2; mmAddr=={0:#010x}; tempSize=={1:d}", mmAddr, tempSize)
            ret += b"\xff"*tempSize
            if (dataSize <= tempSize):
                return ret
            dataSize -= tempSize
            mmAddr += tempSize
        if (dataSize > 0 and mmAddr >= LAST_MEMAREA_BASE_ADDR and mmAddr < SIZE_4GB):
            tempOffset = mmAddr-LAST_MEMAREA_BASE_ADDR
            tempSize = min(dataSize, SIZE_4GB-mmAddr)
            ret += self.romData[tempOffset:tempOffset+tempSize]
        return ret
    cdef signed long int mmPhyReadValueSigned(self, unsigned long int mmAddr, unsigned char dataSize) except? BITMASK_BYTE:
        cdef signed long int ret
        ret = self.mmPhyReadValueUnsigned(mmAddr, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            ret = <signed char>ret
        elif (dataSize == OP_SIZE_WORD):
            ret = <signed short>ret
        elif (dataSize == OP_SIZE_DWORD):
            ret = <signed int>ret
        return ret
    cdef unsigned char mmPhyReadValueUnsignedByte(self, unsigned long int mmAddr) except? BITMASK_BYTE:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_BYTE or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_BYTE)):
            return (<unsigned char*>self.mmGetDataPointer(mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_BYTE)
    cdef unsigned short mmPhyReadValueUnsignedWord(self, unsigned long int mmAddr) except? BITMASK_BYTE:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_WORD or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_WORD)):
            return (<unsigned short*>self.mmGetDataPointer(mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_WORD)
    cdef unsigned int mmPhyReadValueUnsignedDword(self, unsigned long int mmAddr) except? BITMASK_BYTE:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_DWORD or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_DWORD)):
            return (<unsigned int*>self.mmGetDataPointer(mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_DWORD)
    cdef unsigned long int mmPhyReadValueUnsignedQword(self, unsigned long int mmAddr) except? BITMASK_BYTE:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_QWORD or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_QWORD)):
            return (<unsigned long int*>self.mmGetDataPointer(mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_QWORD)
    cdef unsigned long int mmPhyReadValueUnsigned(self, unsigned long int mmAddr, unsigned char dataSize) except? BITMASK_BYTE:
        return int.from_bytes(self.mmPhyRead(mmAddr, dataSize), byteorder="little", signed=False)
    cdef unsigned char mmPhyWrite(self, unsigned long int mmAddr, char *data, unsigned long int dataSize) except BITMASK_BYTE:
        cdef unsigned long int tempOffset, tempSize
        if (dataSize > 0 and mmAddr < self.memSizeBytes):
            tempSize = min(dataSize, self.memSizeBytes-mmAddr)
            with nogil:
                memcpy(<char*>(self.data+mmAddr), <char*>(data), tempSize)
            if (dataSize > 0 and mmAddr < VGA_MEMAREA_ADDR):
                tempSize = min(dataSize, VGA_MEMAREA_ADDR-mmAddr)
                if (dataSize <= tempSize):
                    return True
                dataSize -= tempSize
                mmAddr += tempSize
                data += tempSize
            if (dataSize > 0 and mmAddr >= VGA_MEMAREA_ADDR and mmAddr < VGA_ROM_BASE):
                tempSize = min(dataSize, VGA_ROM_BASE-mmAddr)
                self.main.platform.vga.vgaAreaWrite(mmAddr, tempSize)
        if (dataSize > 0 and mmAddr >= self.memSizeBytes and mmAddr < PCI_MEM_BASE):
            tempSize = min(dataSize, PCI_MEM_BASE-mmAddr)
            self.main.notice("Mm::mmPhyWrite: filling1; mmAddr=={0:#010x}; tempSize=={1:d}", mmAddr, tempSize)
            if (dataSize <= tempSize):
                return True
            dataSize -= tempSize
            mmAddr += tempSize
            data += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE and mmAddr < PCI_MEM_BASE_PLUS_LIMIT):
            tempOffset = mmAddr-PCI_MEM_BASE
            tempSize = min(dataSize, PCI_MEM_BASE_PLUS_LIMIT-mmAddr)
            with nogil:
                memcpy(<char*>(self.pciData+tempOffset), <char*>(data), tempSize)
            if (dataSize <= tempSize):
                return True
            dataSize -= tempSize
            mmAddr += tempSize
            data += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE_PLUS_LIMIT and mmAddr < LAST_MEMAREA_BASE_ADDR):
            tempSize = min(dataSize, LAST_MEMAREA_BASE_ADDR-mmAddr)
            self.main.notice("Mm::mmPhyWrite: filling2; mmAddr=={0:#010x}; tempSize=={1:d}", mmAddr, tempSize)
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
                    memcpy(<char*>(self.romData+tempOffset), <char*>(data), tempSize)
        return True
    cdef unsigned char mmPhyWriteValue(self, unsigned long int mmAddr, unsigned long int data, unsigned char dataSize) except BITMASK_BYTE:
        if (dataSize == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (dataSize == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (dataSize == OP_SIZE_DWORD):
            data = <unsigned int>data
        return self.mmPhyWrite(mmAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
    cdef void mmPhyCopy(self, unsigned long int destAddr, unsigned long int srcAddr, unsigned long int dataSize):
        self.mmPhyWrite(destAddr, self.mmPhyRead(srcAddr, dataSize), dataSize)


cdef class ConfigSpace:
    def __init__(self, unsigned int csSize, Hirnwichse main):
        self.csSize = csSize
        self.main = main
        self.csData = <char*>malloc(self.csSize)
        if (not self.csData):
            self.main.exitError("ConfigSpace::run: not self.csData.")
            return
        self.csResetData()
    cdef void csResetData(self, unsigned char clearByte = 0x00):
        self.clearByte = clearByte
        with nogil:
            memset(self.csData, clearByte, self.csSize)
    cdef bytes csRead(self, unsigned int offset, unsigned int size):
        if ((offset+size) > self.csSize):
            if (self.main.debugEnabled):
                self.main.debug("ConfigSpace::csRead: offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
            return bytes([self.clearByte])*size
        return self.csData[offset:offset+size]
    cdef void csWrite(self, unsigned int offset, char *data, unsigned int size):
        if ((offset+size) > self.csSize):
            if (self.main.debugEnabled):
                self.main.debug("ConfigSpace::csWrite: offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
            return
        with nogil:
            memcpy(<char*>(self.csData+offset), <char*>data, size)
    cdef unsigned long int csReadValueUnsigned(self, unsigned int offset, unsigned char size) except? BITMASK_BYTE:
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
    cdef signed long int csReadValueSigned(self, unsigned int offset, unsigned char size) except? BITMASK_BYTE:
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
    cdef unsigned long int csWriteValue(self, unsigned int offset, unsigned long int data, unsigned char size) except? BITMASK_BYTE:
        if (size == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (size == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (size == OP_SIZE_DWORD):
            data = <unsigned int>data
        #if (self.main.debugEnabled):
        #    self.main.debug("ConfigSpace::csWriteValue: test1. (offset: {0:#06x}, data: {1:#04x}, size: {2:d})", offset, data, size)
        self.csWrite(offset, data.to_bytes(length=size, byteorder="little", signed=False), size)
        return data


