
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"
include "cpu_globals.pxi"

from traceback import print_exc
from atexit import register


cdef class Mm:
    def __init__(self, Hirnwichse main):
        cdef uint16_t i
        self.main = main
        self.ignoreRomWrite = False
        self.memSizeBytes = self.main.memSize*1024*1024
        self.data = self.pciData = self.romData = self.tempData = self.vgaRomData = NULL
        with nogil:
            self.data = <char*>malloc(self.memSizeBytes+OP_SIZE_QWORD)
            self.pciData = <char*>malloc(SIZE_1MB+OP_SIZE_QWORD)
            self.romData = <char*>malloc(SIZE_1MB+OP_SIZE_QWORD)
            self.tempData = <char*>malloc(SIZE_1MB+OP_SIZE_QWORD) # TODO: size
            self.vgaRomData = <char*>malloc(SIZE_1MB+OP_SIZE_QWORD)
        if (self.data is NULL or self.pciData is NULL or self.romData is NULL or self.tempData is NULL or self.vgaRomData is NULL):
            self.main.exitError("Mm::init: not self.data or not self.pciData or not self.romData or not self.tempData or not self.vgaRomData.")
            return
        with nogil:
            memset(self.data, 0, self.memSizeBytes)
            memset(self.pciData, 0, SIZE_1MB)
            memset(self.romData, 0, SIZE_1MB)
            memset(self.tempData, 0, SIZE_1MB)
            memset(self.vgaRomData, 0, SIZE_1MB)
        register(self.quitFunc, self)
    cdef void quitFunc(self):
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
            if (self.vgaRomData is not NULL):
                free(self.vgaRomData)
                self.vgaRomData = NULL
        except:
            print_exc()
            self.main.exitError('Mm::quitFunc: exception, exiting...')
    cdef void mmClear(self, uint32_t offset, uint8_t clearByte, uint32_t dataSize) nogil:
        with nogil:
            memset(self.data+offset, clearByte, dataSize)
    cdef char *mmPhyRead(self, uint32_t mmAddr, uint32_t dataSize) nogil:
        cdef uint32_t tempDataOffset = 0, tempOffset, tempSize, tempVal
        if (dataSize >= SIZE_1MB): # TODO: size
            #with gil: # outcommented because of cython. 'gil ensure' at the beginning of every function which contains 'with gil:'
            #    self.main.exitError('Mm::mmPhyRead: dataSize >= SIZE_1MB, exiting...')
            exitt(1)
            return self.tempData
        if (dataSize > 0 and mmAddr < VGA_MEMAREA_ADDR):
            tempSize = min(dataSize, VGA_MEMAREA_ADDR-mmAddr)
            memcpy(self.tempData+tempDataOffset, self.data+mmAddr, tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= VGA_MEMAREA_ADDR and mmAddr < VGA_ROM_BASE):
            tempSize = min(dataSize, VGA_ROM_BASE-mmAddr)
            memcpy(self.tempData+tempDataOffset, self.main.platform.vga.vgaAreaRead(mmAddr, tempSize), tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= VGA_ROM_BASE and mmAddr < self.memSizeBytes):
            tempSize = min(dataSize, self.memSizeBytes-mmAddr)
            memcpy(self.tempData+tempDataOffset, self.data+mmAddr, tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= self.memSizeBytes and mmAddr < PCI_MEM_BASE):
            tempSize = min(dataSize, PCI_MEM_BASE-mmAddr)
            #self.main.notice("Mm::mmPhyRead: filling1; mmAddr==0x%08x; tempSize==%u", mmAddr, tempSize)
            memset(self.tempData+tempDataOffset, 0xff, tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE and mmAddr < PCI_MEM_BASE_PLUS_LIMIT):
            tempOffset = mmAddr-PCI_MEM_BASE
            tempSize = min(dataSize, PCI_MEM_BASE_PLUS_LIMIT-mmAddr)
            memcpy(self.tempData+tempDataOffset, self.pciData+tempOffset, tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE_PLUS_LIMIT and mmAddr < self.main.cpu.registers.apicBaseReal):
            tempSize = min(dataSize, self.main.cpu.registers.apicBaseReal-mmAddr)
            if (mmAddr >= self.main.platform.vga.romBaseReal and mmAddr < self.main.platform.vga.romBaseRealPlusSize): # TODO/HACK
                tempOffset = mmAddr-self.main.platform.vga.romBaseReal
                #self.main.notice("Mm::mmPhyRead: filling_test1; 0x%08x", (<uint32_t*>self.vgaRomData)[0])
                memcpy(self.tempData+tempDataOffset, self.vgaRomData+tempOffset, tempSize)
            else:
                memset(self.tempData+tempDataOffset, 0xff, tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= self.main.cpu.registers.apicBaseReal and mmAddr < self.main.cpu.registers.apicBaseRealPlusSize):
            tempOffset = mmAddr-self.main.cpu.registers.apicBaseReal
            tempSize = min(dataSize, self.main.cpu.registers.apicBaseRealPlusSize-mmAddr)
            memset(self.tempData+tempDataOffset, 0, tempSize)
            #tempVal = 0x12345678 # testcase
            tempVal = (3<<16)|0xf
            memcpy(self.tempData+tempDataOffset-tempOffset+0x30, &tempVal, OP_SIZE_DWORD)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= self.main.cpu.registers.apicBaseRealPlusSize and mmAddr < LAST_MEMAREA_BASE_ADDR):
            tempSize = min(dataSize, LAST_MEMAREA_BASE_ADDR-mmAddr)
            #self.main.notice("Mm::mmPhyRead: filling4; mmAddr==0x%08x; tempSize==%u", mmAddr, tempSize)
            memset(self.tempData+tempDataOffset, 0xff, tempSize)
            if (dataSize <= tempSize):
                return self.tempData
            dataSize -= tempSize
            mmAddr += tempSize
            tempDataOffset += tempSize
        if (dataSize > 0 and mmAddr >= LAST_MEMAREA_BASE_ADDR and mmAddr < SIZE_4GB):
            tempOffset = mmAddr-LAST_MEMAREA_BASE_ADDR
            tempSize = min(dataSize, SIZE_4GB-mmAddr)
            memcpy(self.tempData+tempDataOffset, self.romData+tempOffset, tempSize)
        return self.tempData
    cdef int64_t mmPhyReadValueSigned(self, uint32_t mmAddr, uint8_t dataSize) nogil:
        cdef int64_t ret
        ret = self.mmPhyReadValueUnsigned(mmAddr, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            ret = <int8_t>ret
        elif (dataSize == OP_SIZE_WORD):
            ret = <int16_t>ret
        elif (dataSize == OP_SIZE_DWORD):
            ret = <int32_t>ret
        return ret
    cdef uint8_t mmPhyReadValueUnsignedByte(self, uint32_t mmAddr) nogil:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_BYTE or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_BYTE)):
            return (<uint8_t*>(self.data+mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_BYTE)
    cdef uint16_t mmPhyReadValueUnsignedWord(self, uint32_t mmAddr) nogil:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_WORD or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_WORD)):
            return (<uint16_t*>(self.data+mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_WORD)
    cdef uint32_t mmPhyReadValueUnsignedDword(self, uint32_t mmAddr) nogil:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_DWORD or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_DWORD)):
            return (<uint32_t*>(self.data+mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_DWORD)
    cdef uint64_t mmPhyReadValueUnsignedQword(self, uint32_t mmAddr) nogil:
        if (mmAddr <= VGA_MEMAREA_ADDR-OP_SIZE_QWORD or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-OP_SIZE_QWORD)):
            return (<uint64_t*>(self.data+mmAddr))[0]
        return self.mmPhyReadValueUnsigned(mmAddr, OP_SIZE_QWORD)
    cdef uint64_t mmPhyReadValueUnsigned(self, uint32_t mmAddr, uint8_t dataSize) nogil:
        cdef char *temp
        if (mmAddr <= VGA_MEMAREA_ADDR-dataSize or (mmAddr >= VGA_ROM_BASE and mmAddr <= self.memSizeBytes-dataSize)):
            temp = self.data+mmAddr
        else:
            temp = self.mmPhyRead(mmAddr, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            return (<uint8_t*>temp)[0]
        elif (dataSize == OP_SIZE_WORD):
            return (<uint16_t*>temp)[0]
        elif (dataSize == OP_SIZE_DWORD):
            return (<uint32_t*>temp)[0]
        return (<uint64_t*>temp)[0]
    cdef uint8_t mmPhyWrite(self, uint32_t mmAddr, char *data, uint32_t dataSize) nogil:
        cdef uint32_t tempOffset, tempSize
        if (dataSize > 0 and mmAddr < SIZE_1MB):
            if (mmAddr < VGA_MEMAREA_ADDR):
                tempSize = min(dataSize, VGA_MEMAREA_ADDR-mmAddr)
                with nogil:
                    memcpy(self.data+mmAddr, data, tempSize)
                if (dataSize <= tempSize):
                    return True
                dataSize -= tempSize
                mmAddr += tempSize
                data += tempSize
            if (dataSize > 0 and mmAddr >= VGA_MEMAREA_ADDR and mmAddr < VGA_ROM_BASE):
                tempSize = min(dataSize, VGA_ROM_BASE-mmAddr)
                with nogil:
                    memcpy(self.data+mmAddr, data, tempSize)
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
                        memcpy(self.data+mmAddr, data, tempSize)
                        #memcpy(self.vgaRomData+mmAddr-VGA_ROM_BASE, data, tempSize)
                    #self.main.notice("Mm::mmPhyWrite: vgarom_test1; 0x%08x", (<uint32_t*>self.vgaRomData)[0])
                if (dataSize <= tempSize):
                    return True
                dataSize -= tempSize
                mmAddr += tempSize
                data += tempSize
        if (dataSize > 0 and mmAddr >= SIZE_1MB and mmAddr < self.memSizeBytes):
            tempSize = min(dataSize, self.memSizeBytes-mmAddr)
            with nogil:
                memcpy(self.data+mmAddr, data, tempSize)
            if (dataSize <= tempSize):
                return True
            dataSize -= tempSize
            mmAddr += tempSize
            data += tempSize
        if (dataSize > 0 and mmAddr >= self.memSizeBytes and mmAddr < PCI_MEM_BASE):
            tempSize = min(dataSize, PCI_MEM_BASE-mmAddr)
            #self.main.notice("Mm::mmPhyWrite: filling1; mmAddr==0x%08x; tempSize==%u", mmAddr, tempSize)
            if (dataSize <= tempSize):
                return True
            dataSize -= tempSize
            mmAddr += tempSize
            data += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE and mmAddr < PCI_MEM_BASE_PLUS_LIMIT):
            tempOffset = mmAddr-PCI_MEM_BASE
            tempSize = min(dataSize, PCI_MEM_BASE_PLUS_LIMIT-mmAddr)
            with nogil:
                memcpy(self.pciData+tempOffset, data, tempSize)
            if (dataSize <= tempSize):
                return True
            dataSize -= tempSize
            mmAddr += tempSize
            data += tempSize
        if (dataSize > 0 and mmAddr >= PCI_MEM_BASE_PLUS_LIMIT and mmAddr < self.main.cpu.registers.apicBaseReal):
            tempSize = min(dataSize, self.main.cpu.registers.apicBaseReal-mmAddr)
            self.main.notice("Mm::mmPhyWrite: filling2; mmAddr==0x%08x; tempSize==%u", mmAddr, tempSize)
            if (mmAddr >= self.main.platform.vga.romBaseReal and mmAddr < self.main.platform.vga.romBaseRealPlusSize): # TODO/HACK
                tempOffset = mmAddr-self.main.platform.vga.romBaseReal
                with nogil:
                    memcpy(self.vgaRomData+tempOffset, data, tempSize)
            if (dataSize <= tempSize):
                return True
            dataSize -= tempSize
            mmAddr += tempSize
            data += tempSize
        if (dataSize > 0 and mmAddr >= self.main.cpu.registers.apicBaseReal and mmAddr < self.main.cpu.registers.apicBaseRealPlusSize):
            tempOffset = mmAddr-self.main.cpu.registers.apicBaseReal
            tempSize = min(dataSize, self.main.cpu.registers.apicBaseRealPlusSize-mmAddr)
            ###
            if (dataSize <= tempSize):
                return True
            dataSize -= tempSize
            mmAddr += tempSize
            data += tempSize
        if (dataSize > 0 and mmAddr >= self.main.cpu.registers.apicBaseRealPlusSize and mmAddr < LAST_MEMAREA_BASE_ADDR):
            tempSize = min(dataSize, LAST_MEMAREA_BASE_ADDR-mmAddr)
            #self.main.notice("Mm::mmPhyWrite: filling3; mmAddr==0x%08x; tempSize==%u", mmAddr, tempSize)
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
                    memcpy(self.romData+tempOffset, data, tempSize)
        return True
    cdef uint8_t mmPhyWriteValue(self, uint32_t mmAddr, uint64_t data, uint8_t dataSize) nogil:
        cdef char *temp
        if (dataSize == OP_SIZE_BYTE):
            data = <uint8_t>data
        elif (dataSize == OP_SIZE_WORD):
            data = <uint16_t>data
        elif (dataSize == OP_SIZE_DWORD):
            data = <uint32_t>data
        #elif (dataSize != OP_SIZE_QWORD):
        #    return self.mmPhyWrite(mmAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
        temp = <char*>&data
        return self.mmPhyWrite(mmAddr, temp, dataSize)


cdef class ConfigSpace:
    def __init__(self, uint32_t csSize, Hirnwichse main):
        self.csSize = csSize
        self.main = main
        self.csData = <char*>malloc(self.csSize+OP_SIZE_QWORD)
        if (not self.csData):
            self.main.exitError("ConfigSpace::run: not self.csData.")
            return
        self.csResetData(0)
        register(self.quitFunc, self)
    cdef void quitFunc(self):
        try:
            self.main.quitFunc()
            if (self.csData is not NULL):
                free(self.csData)
                self.csData = NULL
        except:
            print_exc()
            self.main.exitError('ConfigSpace::quitFunc: exception, exiting...')
    cdef void csResetData(self, uint8_t clearByte) nogil:
        self.clearByte = clearByte
        with nogil:
            memset(self.csData, clearByte, self.csSize)
    cdef void csResetAddr(self, uint32_t offset, uint8_t clearByte, uint8_t size) nogil:
        with nogil:
            memset(self.csData+offset, clearByte, size)
    cdef bytes csRead(self, uint32_t offset, uint32_t size):
        cdef bytes data
        cdef uint32_t tempSize
        tempSize = min(size, self.csSize-offset)
        #if (offset >= self.csSize):
        IF 0:
            #if (self.main.debugEnabled):
            IF COMP_DEBUG:
                self.main.notice("ConfigSpace::csRead: offset >= self.csSize. (offset: 0x%04x, tempSize: %u, size: %u, self.csSize: 0x%04x)", offset, tempSize, size, self.csSize)
            return bytes([self.clearByte])*size
        data = self.csData[offset:offset+tempSize]
        size -= tempSize
        if (size > 0):
            #if (self.main.debugEnabled):
            IF COMP_DEBUG:
                self.main.notice("ConfigSpace::csRead: offset+size > self.csSize. (offset: 0x%04x, size: %u)", offset, size)
            data += bytes([self.clearByte])*size
        return data
    cdef void csWrite(self, uint32_t offset, char *data, uint32_t size) nogil:
        cdef uint32_t tempSize
        tempSize = min(size, self.csSize-offset)
        #if (offset >= self.csSize):
        IF 0:
            #if (self.main.debugEnabled):
            IF COMP_DEBUG:
                self.main.notice("ConfigSpace::csWrite: offset >= self.csSize. (offset: 0x%04x, tempSize: %u, size: %u, self.csSize: 0x%04x)", offset, tempSize, size, self.csSize)
            return
        with nogil:
            memcpy(self.csData+offset, data, tempSize)
        size -= tempSize
        if (size > 0):
            #if (self.main.debugEnabled):
            IF COMP_DEBUG:
                self.main.notice("ConfigSpace::csWrite: offset+size > self.csSize. (offset: 0x%04x, size: %u)", offset, size)
    cdef uint64_t csReadValueUnsigned(self, uint32_t offset, uint8_t size) nogil:
        cdef uint64_t ret
        #if (self.main.debugEnabled):
        #    self.main.debug("ConfigSpace::csReadValueUnsigned: test1. (offset: 0x%04x, size: %u)", offset, size)
        #if (offset >= self.csSize):
        IF 0:
            #if (self.main.debugEnabled):
            IF COMP_DEBUG:
                self.main.notice("ConfigSpace::csReadValueUnsigned: offset >= self.csSize. (offset: 0x%04x, size: %u, self.csSize: 0x%04x)", offset, size, self.csSize)
            return 0
        ret = (<uint64_t*>(self.csData+offset))[0]
        if (size == OP_SIZE_BYTE):
            ret = <uint8_t>ret
        elif (size == OP_SIZE_WORD):
            ret = <uint16_t>ret
        elif (size == OP_SIZE_DWORD):
            ret = <uint32_t>ret
        return ret
    cdef int64_t csReadValueSigned(self, uint32_t offset, uint8_t size) nogil:
        cdef int64_t ret
        #if (self.main.debugEnabled):
        #    self.main.debug("ConfigSpace::csReadValueSigned: test1. (offset: 0x%04x, size: %u)", offset, size)
        #if (offset >= self.csSize):
        IF 0:
            #if (self.main.debugEnabled):
            IF COMP_DEBUG:
                self.main.notice("ConfigSpace::csReadValueSigned: offset >= self.csSize. (offset: 0x%04x, size: %u, self.csSize: 0x%04x)", offset, size, self.csSize)
            return 0
        ret = (<int64_t*>(self.csData+offset))[0]
        if (size == OP_SIZE_BYTE):
            ret = <int8_t>ret
        elif (size == OP_SIZE_WORD):
            ret = <int16_t>ret
        elif (size == OP_SIZE_DWORD):
            ret = <int32_t>ret
        return ret
    cdef uint64_t csWriteValue(self, uint32_t offset, uint64_t data, uint8_t size) nogil:
        #if (offset >= self.csSize):
        IF 0:
            #if (self.main.debugEnabled):
            IF COMP_DEBUG:
                self.main.notice("ConfigSpace::csWriteValue: offset >= self.csSize. (offset: 0x%04x, size: %u, self.csSize: 0x%04x)", offset, size, self.csSize)
            return 0
        if (size == OP_SIZE_BYTE):
            data = <uint8_t>data
        elif (size == OP_SIZE_WORD):
            data = <uint16_t>data
        elif (size == OP_SIZE_DWORD):
            data = <uint32_t>data
        #elif (size != OP_SIZE_QWORD):
        #    self.csWrite(offset, data.to_bytes(length=size, byteorder="little", signed=False), size)
        #    return data
        #if (self.main.debugEnabled):
        #    self.main.debug("ConfigSpace::csWriteValue: test1. (offset: 0x%04x, data: 0x%02x, size: %u)", offset, data, size)
        self.csWrite(offset, <char*>&data, size)
        return data


