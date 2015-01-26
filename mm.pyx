
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"
include "cpu_globals.pxi"

from atexit import register

DEF MM_NUMAREAS = 4096

cdef class MmArea:
    def __init__(self):
        self.valid = False
        self.data = NULL

cdef class Mm:
    def __init__(self, object main):
        cdef unsigned int i
        cdef list mmAreas
        self.main = main
        mmAreas = []
        for i in range(MM_NUMAREAS):
            mmAreas.append(MmArea())
        self.mmAreas = tuple(mmAreas+mmAreas)
    cdef MmArea mmAddArea(self, unsigned int start, unsigned char readOnly):
        cdef MmArea mmArea
        mmArea = self.mmGetArea(start)
        mmArea.valid = True
        mmArea.readOnly = readOnly
        self.mmMallocArea(mmArea, 0x00)
        mmArea.readClass  = self
        mmArea.writeClass = self
        mmArea.readHandler  = <MmAreaReadType>self.mmAreaRead
        mmArea.writeHandler = <MmAreaWriteType>self.mmAreaWrite
        return mmArea
    cdef void mmMallocArea(self, MmArea mmArea, unsigned char clearByte):
        if (mmArea.data is NULL):
            mmArea.data = <char*>malloc(SIZE_1MB)
            if (mmArea.data is NULL):
                self.main.exitError("Mm::mmAddArea: not mmArea.data.")
                return
        memset(mmArea.data, clearByte, SIZE_1MB)
    cdef MmArea mmGetArea(self, unsigned int mmAddr):
        mmAddr >>= 20
        return self.mmAreas[mmAddr]
    cdef tuple mmGetAreas(self, unsigned int mmAddr, unsigned int dataSize):
        cdef MmArea mmArea
        cdef unsigned short begin, end
        cdef tuple mmAreas
        end = ((mmAddr+dataSize-1) >> 20) + 1
        begin = (mmAddr) >> 20
        mmAreas = self.mmAreas[begin:end]
        return mmAreas
    cdef void mmSetReadOnly(self, unsigned int mmAddr, unsigned char readOnly):
        cdef MmArea mmArea = self.mmGetArea(mmAddr)
        if (not mmArea.valid):
            self.main.exitError("Mm::mmSetReadOnly: mmArea is invalid!")
            return
        mmArea.readOnly = readOnly
    cdef bytes mmAreaRead(self, MmArea mmArea, unsigned int offset, unsigned int dataSize):
        return mmArea.data[offset:offset+dataSize]
    cdef void mmAreaWrite(self, MmArea mmArea, unsigned int offset, char *data, unsigned int dataSize):
        with nogil:
            memmove(<char*>(mmArea.data+offset), data, dataSize)
    cdef bytes mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize):
        cdef MmArea mmArea
        cdef unsigned int tempAddr, tempSize
        cdef bytes data = bytes()
        cdef tuple mmAreas = self.mmGetAreas(mmAddr, dataSize)
        for mmArea in mmAreas:
            tempSize = min(SIZE_1MB, dataSize)
            tempAddr = (mmAddr&SIZE_1MB_MASK)
            if (tempAddr+tempSize > SIZE_1MB):
                tempSize = min(SIZE_1MB-tempAddr, tempSize)
            if (mmArea.valid):
                data += mmArea.readHandler(mmArea.readClass, mmArea, tempAddr, tempSize)
            else:
                self.main.notice("Mm::mmPhyRead: not mmArea.valid! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, tempSize)
                data += b'\xff'*tempSize
            mmAddr += tempSize
            dataSize -= tempSize
        return data
    cdef signed long int mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(self.mmPhyRead(mmAddr, dataSize), byteorder="little", signed=True)
    cdef unsigned char mmPhyReadValueUnsignedByte(self, unsigned int mmAddr):
        cdef MmArea mmArea = self.mmGetArea(mmAddr)
        if (not mmArea.valid):
            self.main.notice("Mm::mmPhyReadValueUnsignedByte: not mmArea.valid! (mmAddr: {0:#010x}; savedEip: {1:#010x}; savedCs: {2:#06x})", mmAddr, self.main.cpu.savedEip, self.main.cpu.savedCs)
            return BITMASK_BYTE
        mmAddr &= SIZE_1MB_MASK
        return (<unsigned char*>self.mmGetDataPointer(mmArea, mmAddr))[0]
    cdef unsigned short mmPhyReadValueUnsignedWord(self, unsigned int mmAddr):
        cdef MmArea mmArea = self.mmGetArea(mmAddr)
        cdef unsigned char dataSize = OP_SIZE_WORD
        cdef unsigned int tempAddr
        if (not mmArea.valid):
            self.main.notice("Mm::mmPhyReadValueUnsignedWord: not mmArea.valid! (mmAddr: {0:#010x}; savedEip: {1:#010x}; savedCs: {2:#06x})", mmAddr, self.main.cpu.savedEip, self.main.cpu.savedCs)
            return BITMASK_WORD
        tempAddr = (mmAddr&SIZE_1MB_MASK)
        if (tempAddr+dataSize > SIZE_1MB):
            return self.mmPhyReadValueUnsigned(mmAddr, dataSize)
        return (<unsigned short*>self.mmGetDataPointer(mmArea, tempAddr))[0]
    cdef unsigned int mmPhyReadValueUnsignedDword(self, unsigned int mmAddr):
        cdef MmArea mmArea = self.mmGetArea(mmAddr)
        cdef unsigned char dataSize = OP_SIZE_DWORD
        cdef unsigned int tempAddr
        if (not mmArea.valid):
            self.main.notice("Mm::mmPhyReadValueUnsignedDword: not mmArea.valid! (mmAddr: {0:#010x}; savedEip: {1:#010x}; savedCs: {2:#06x})", mmAddr, self.main.cpu.savedEip, self.main.cpu.savedCs)
            return BITMASK_DWORD
        tempAddr = (mmAddr&SIZE_1MB_MASK)
        if (tempAddr+dataSize > SIZE_1MB):
            return self.mmPhyReadValueUnsigned(mmAddr, dataSize)
        return (<unsigned int*>self.mmGetDataPointer(mmArea, tempAddr))[0]
    cdef unsigned long int mmPhyReadValueUnsignedQword(self, unsigned int mmAddr):
        cdef MmArea mmArea = self.mmGetArea(mmAddr)
        cdef unsigned char dataSize = OP_SIZE_QWORD
        cdef unsigned int tempAddr
        if (not mmArea.valid):
            self.main.notice("Mm::mmPhyReadValueUnsignedQword: not mmArea.valid! (mmAddr: {0:#010x}; savedEip: {1:#010x}; savedCs: {2:#06x})", mmAddr, self.main.cpu.savedEip, self.main.cpu.savedCs)
            return BITMASK_QWORD
        tempAddr = (mmAddr&SIZE_1MB_MASK)
        if (tempAddr+dataSize > SIZE_1MB):
            return self.mmPhyReadValueUnsigned(mmAddr, dataSize)
        return (<unsigned long int*>self.mmGetDataPointer(mmArea, tempAddr))[0]
    cdef unsigned long int mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(self.mmPhyRead(mmAddr, dataSize), byteorder="little", signed=False)
    cdef unsigned char mmPhyWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize):
        cdef MmArea mmArea
        cdef unsigned int tempAddr, tempSize
        cdef tuple mmAreas
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        for mmArea in mmAreas:
            tempSize = min(SIZE_1MB, dataSize)
            tempAddr = (mmAddr&SIZE_1MB_MASK)
            if (tempAddr+tempSize > SIZE_1MB):
                tempSize = SIZE_1MB-tempAddr
            if (mmArea.valid):
                mmArea.writeHandler(mmArea.writeClass, mmArea, tempAddr, data, tempSize)
            else:
                self.main.notice("Mm::mmPhyWrite: not mmArea.valid! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, tempSize)
            mmAddr += tempSize
            dataSize -= tempSize
            data = data[tempSize:]
        return True
    cdef unsigned char mmPhyWriteValueSize(self, unsigned int mmAddr, unsigned_value_types data):
        cdef MmArea mmArea
        cdef unsigned char dataSize = 0
        cdef unsigned int tempAddr
        cdef tuple mmAreas
        if (unsigned_value_types is unsigned_char):
            dataSize = OP_SIZE_BYTE
        elif (unsigned_value_types is unsigned_short):
            dataSize = OP_SIZE_WORD
        elif (unsigned_value_types is unsigned_int):
            dataSize = OP_SIZE_DWORD
        elif (unsigned_value_types is unsigned_long_int):
            dataSize = OP_SIZE_QWORD
        else:
            self.main.error("Mm::mmPhyWrite: invalid unsigned_value_types.")
            return False
        if (unsigned_value_types is unsigned_char):
            mmArea = self.mmGetArea(mmAddr)
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyWrite: not mmArea.valid 1! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return False
            tempAddr = (mmAddr&SIZE_1MB_MASK)
            mmArea.writeHandler(mmArea.writeClass, mmArea, tempAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
            return True
        else:
            mmAreas = self.mmGetAreas(mmAddr, dataSize)
            for mmArea in mmAreas:
                if (not mmArea.valid):
                    self.main.notice("Mm::mmPhyWrite: not mmArea.valid 2! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                    return False
                tempAddr = (mmAddr&SIZE_1MB_MASK)
                if (tempAddr+dataSize > SIZE_1MB):
                    return self.mmPhyWriteValue(mmAddr, data, dataSize)
                mmArea.writeHandler(mmArea.writeClass, mmArea, tempAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
                return True
    cdef unsigned char mmPhyWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (dataSize == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (dataSize == OP_SIZE_DWORD):
            data = <unsigned int>data
        return self.mmPhyWrite(mmAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
    cdef void mmPhyCopy(self, unsigned int destAddr, unsigned int srcAddr, unsigned int dataSize):
        self.mmPhyWrite(destAddr, self.mmPhyRead(srcAddr, dataSize), dataSize)


cdef class ConfigSpace:
    def __init__(self, unsigned int csSize, object main):
        self.csSize = csSize
        self.main = main
        self.csData = <char*>malloc(self.csSize)
        if (not self.csData):
            self.main.exitError("ConfigSpace::run: not self.csData.")
            return
        self.csResetData()
    cdef void csResetData(self, unsigned char clearByte = 0x00):
        self.clearByte = clearByte
        memset(self.csData, clearByte, self.csSize)
    cdef bytes csRead(self, unsigned int offset, unsigned int size):
        if ((offset+size) > self.csSize):
            self.main.debug("ConfigSpace::csRead: offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
            return bytes([self.clearByte])*size
        return self.csData[offset:offset+size]
    cdef void csWrite(self, unsigned int offset, bytes data, unsigned int size):
        if ((offset+size) > self.csSize):
            self.main.debug("ConfigSpace::csWrite: offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
            return
        memmove(<char*>(self.csData+offset), <char*>data, size)
    cdef unsigned long int csReadValueUnsigned(self, unsigned int offset, unsigned char size):
        return int.from_bytes(self.csRead(offset, size), byteorder="little", signed=False)
    cdef unsigned long int csReadValueUnsignedBE(self, unsigned int offset, unsigned char size): # Big Endian
        return int.from_bytes(self.csRead(offset, size), byteorder="big", signed=False)
    cdef signed long int csReadValueSigned(self, unsigned int offset, unsigned char size):
        return int.from_bytes(self.csRead(offset, size), byteorder="little", signed=True)
    cdef signed long int csReadValueSignedBE(self, unsigned int offset, unsigned char size): # Big Endian
        return int.from_bytes(self.csRead(offset, size), byteorder="big", signed=True)
    cdef unsigned long int csWriteValue(self, unsigned int offset, unsigned long int data, unsigned char size):
        if (size == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (size == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (size == OP_SIZE_DWORD):
            data = <unsigned int>data
        self.csWrite(offset, data.to_bytes(length=size, byteorder="little", signed=False), size)
        return data
    cdef unsigned long int csWriteValueBE(self, unsigned int offset, unsigned long int data, unsigned char size): # Big Endian
        if (size == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (size == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (size == OP_SIZE_DWORD):
            data = <unsigned int>data
        self.csWrite(offset, data.to_bytes(length=size, byteorder="big", signed=False), size)
        return data


