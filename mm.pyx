
from atexit import register

include "globals.pxi"
include "cpu_globals.pxi"

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
        self.mmAreas = mmAreas
    cdef MmArea mmAddArea(self, unsigned int start, unsigned char readOnly):
        cdef MmArea mmArea
        mmArea = self.mmGetArea(start)
        mmArea.valid = True
        mmArea.start = start
        mmArea.end  = mmArea.start+SIZE_1MB-1
        mmArea.readOnly = readOnly
        if (mmArea.end < mmArea.start):
            self.main.exitError("Mm::mmAddArea: mem-address overflow.")
            return None
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
    cdef void mmDelArea(self, unsigned int mmAddr):
        cdef MmArea mmArea = self.mmGetArea(mmAddr)
        if (mmArea.valid and mmArea.data is not NULL):
            free(mmArea.data)
            mmArea.data = NULL
        mmArea.valid = False
    cdef MmArea mmGetArea(self, unsigned int mmAddr):
        mmAddr >>= 20
        if (mmAddr >= MM_NUMAREAS):
            return None
        return self.mmAreas[mmAddr]
    cdef list mmGetAreas(self, unsigned int mmAddr, unsigned int dataSize):
        cdef MmArea mmArea
        cdef unsigned short begin, end, count, i
        cdef list mmAreas
        mmAreas = []
        end = (mmAddr+dataSize-1) >> 20
        begin = (mmAddr) >> 20
        count = (end-begin+1)&0xfff
        for i in range(count):
            mmArea = self.mmAreas[(begin+i)&0xfff]
            if (not mmArea.valid):
                mmArea = None
                continue
            mmAreas.append(mmArea)
        if (mmArea is None):
            return None
        return mmAreas
    cdef void mmSetReadOnly(self, unsigned int mmAddr, unsigned char readOnly):
        cdef MmArea mmArea = self.mmGetArea(mmAddr)
        if (mmArea is None or not mmArea.valid):
            self.main.exitError("Mm::mmSetReadOnly: mmArea is invalid!")
            return
        mmArea.readOnly = readOnly
    cdef bytes mmAreaRead(self, MmArea mmArea, unsigned int offset, unsigned int dataSize):
        if (not mmArea.valid or mmArea.data is NULL or not dataSize):
            if (mmArea.data is not NULL):
                self.main.exitError("Mm::mmAreaRead: not mmArea(.valid) || not dataSize. (address: {0:#010x}, dataSize: {1:d})", \
                  mmArea.start+offset, dataSize)
            return b'\xff'*dataSize
        return mmArea.data[offset:offset+dataSize]
    cdef void mmAreaWrite(self, MmArea mmArea, unsigned int offset, char *data, unsigned int dataSize):
        if (not mmArea.valid or mmArea.readOnly or not dataSize):
            self.main.exitError("Mm::mmAreaWrite: not mmArea.valid || mmArea.readOnly || not dataSize. (address: {0:#010x}, dataSize: {1:d}, readOnly: {2:d})", \
              mmArea.start+offset, dataSize, mmArea.readOnly)
            return
        elif (mmArea.data is NULL):
            self.mmMallocArea(mmArea, 0x00)
        with nogil:
            memcpy(<char*>(mmArea.data+offset), data, dataSize)
    cdef bytes mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize):
        cdef MmArea mmArea
        cdef unsigned int tempAddr, tempSize, origMmAddr = mmAddr, tempDataSize = dataSize
        cdef bytes data = bytes()
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (mmAreas is None):
            self.main.notice("Mm::mmPhyRead: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", origMmAddr, dataSize)
            return b'\xff'*dataSize
        tempSize = min(SIZE_1MB, dataSize)
        for mmArea in mmAreas:
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            tempSize = min(tempSize, tempDataSize)
            if (tempAddr+tempSize > SIZE_1MB):
                tempSize = min(SIZE_1MB-tempAddr, tempDataSize)
            data += mmArea.readHandler(mmArea.readClass, mmArea, tempAddr, tempSize)
            mmAddr += tempSize
            tempDataSize -= tempSize
            tempSize = dataSize-tempSize
        if (tempDataSize):
            self.main.exitError("Mm::mmPhyRead: tempDataSize: {0:#06x} is not zero. (mmAddr: {1:#010x}, dataSize: {2:d})", tempDataSize, origMmAddr, dataSize)
            return b'\xff'*dataSize
        return data
    cdef signed char mmPhyReadValueSignedByte(self, unsigned int mmAddr):
        cdef MmArea mmArea = self.mmGetArea(mmAddr)
        cdef unsigned char dataSize = OP_SIZE_BYTE
        cdef unsigned int tempAddr
        if (mmArea is None):
            self.main.notice("Mm::mmPhyReadValueSignedByte: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return <signed char>BITMASK_BYTE
        tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
        return (<signed char*>self.mmGetDataPointer(mmArea, tempAddr))[0]
    cdef signed short mmPhyReadValueSignedWord(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef unsigned char dataSize = OP_SIZE_WORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (mmAreas is None or not len(mmAreas)):
            self.main.notice("Mm::mmPhyReadValueSignedWord: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return <signed short>BITMASK_WORD
        for mmArea in mmAreas:
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueSigned(mmAddr, dataSize)
            return (<signed short*>self.mmGetDataPointer(mmArea, tempAddr))[0]
    cdef signed int mmPhyReadValueSignedDword(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef unsigned char dataSize = OP_SIZE_DWORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (mmAreas is None or not len(mmAreas)):
            self.main.notice("Mm::mmPhyReadValueSignedDword: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return <signed int>BITMASK_DWORD
        for mmArea in mmAreas:
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueSigned(mmAddr, dataSize)
            return (<signed int*>self.mmGetDataPointer(mmArea, tempAddr))[0]
    cdef signed long int mmPhyReadValueSignedQword(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef unsigned char dataSize = OP_SIZE_QWORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (mmAreas is None or not len(mmAreas)):
            self.main.notice("Mm::mmPhyReadValueSignedQword: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return <signed long int>BITMASK_QWORD
        for mmArea in mmAreas:
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueSigned(mmAddr, dataSize)
            return (<signed long int*>self.mmGetDataPointer(mmArea, tempAddr))[0]
    cdef signed long int mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(<bytes>(self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=True)
    cdef unsigned char mmPhyReadValueUnsignedByte(self, unsigned int mmAddr):
        cdef MmArea mmArea = self.mmGetArea(mmAddr)
        cdef unsigned char dataSize = OP_SIZE_BYTE
        cdef unsigned int tempAddr
        if (mmArea is None):
            self.main.notice("Mm::mmPhyReadValueUnsignedByte: mmArea not found! (mmAddr: {0:#010x}; savedEip: {1:#010x}; savedCs: {2:#06x})", mmAddr, self.main.cpu.savedEip, self.main.cpu.savedCs)
            return BITMASK_BYTE
        tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
        return (<unsigned char*>self.mmGetDataPointer(mmArea, tempAddr))[0]
    cdef unsigned short mmPhyReadValueUnsignedWord(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef unsigned char dataSize = OP_SIZE_WORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (mmAreas is None or not len(mmAreas)):
            self.main.notice("Mm::mmPhyReadValueUnsignedWord: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return BITMASK_WORD
        for mmArea in mmAreas:
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueUnsigned(mmAddr, dataSize)
            return (<unsigned short*>self.mmGetDataPointer(mmArea, tempAddr))[0]
    cdef unsigned int mmPhyReadValueUnsignedDword(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef unsigned char dataSize = OP_SIZE_DWORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (mmAreas is None or not len(mmAreas)):
            self.main.notice("Mm::mmPhyReadValueUnsignedDword: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return BITMASK_DWORD
        for mmArea in mmAreas:
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueUnsigned(mmAddr, dataSize)
            return (<unsigned int*>self.mmGetDataPointer(mmArea, tempAddr))[0]
    cdef unsigned long int mmPhyReadValueUnsignedQword(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef unsigned char dataSize = OP_SIZE_QWORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (mmAreas is None or not len(mmAreas)):
            self.main.notice("Mm::mmPhyReadValueUnsignedQword: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return BITMASK_QWORD
        for mmArea in mmAreas:
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueUnsigned(mmAddr, dataSize)
            return (<unsigned long int*>self.mmGetDataPointer(mmArea, tempAddr))[0]
    cdef unsigned long int mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(<bytes>(self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=False)
    cdef unsigned char mmPhyWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize):
        cdef MmArea mmArea
        cdef unsigned int tempAddr, tempSize, origMmAddr = mmAddr, tempDataSize = dataSize
        cdef list mmAreas
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (mmAreas is None):
            self.main.notice("Mm::mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", origMmAddr, dataSize)
            return False
        tempSize = min(SIZE_1MB, dataSize)
        for mmArea in mmAreas:
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            tempSize = min(tempSize, tempDataSize)
            if (tempAddr+tempSize > SIZE_1MB):
                tempSize = min(SIZE_1MB-tempAddr, tempDataSize)
            mmArea.writeHandler(mmArea.writeClass, mmArea, tempAddr, data, tempSize)
            mmAddr += tempSize
            tempDataSize -= tempSize
            tempSize = dataSize-tempSize
        if (tempDataSize):
            self.main.exitError("Mm::mmPhyWrite: tempDataSize: {0:#06x} is not zero. (mmAddr: {1:#010x}, dataSize: {2:d})", tempDataSize, origMmAddr, dataSize)
            return False
        return True
    cdef unsigned char mmPhyWriteValueSize(self, unsigned int mmAddr, unsigned_value_types data):
        cdef MmArea mmArea
        cdef unsigned char dataSize = 0
        cdef unsigned int tempAddr
        cdef list mmAreas
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
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (mmAreas is None):
            self.main.notice("Mm::mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            return False
        if (unsigned_value_types is unsigned_char):
            mmArea = self.mmGetArea(mmAddr)
            if (mmArea is None):
                self.main.notice("Mm::mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return False
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            mmArea.writeHandler(mmArea.writeClass, mmArea, tempAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
            return True
        else:
            mmAreas = self.mmGetAreas(mmAddr, dataSize)
            if (mmAreas is None or not len(mmAreas)):
                self.main.notice("Mm::mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return False
            for mmArea in mmAreas:
                tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
                if (tempAddr+dataSize > SIZE_1MB):
                    return self.mmPhyWriteValue(mmAddr, data, dataSize)
                mmArea.writeHandler(mmArea.writeClass, mmArea, tempAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
                return True
    cdef unsigned char mmPhyWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            data &= BITMASK_BYTE
        elif (dataSize == OP_SIZE_WORD):
            data &= BITMASK_WORD
        elif (dataSize == OP_SIZE_DWORD):
            data &= BITMASK_DWORD
        return self.mmPhyWrite(mmAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
    cdef void mmPhyCopy(self, unsigned int destAddr, unsigned int srcAddr, unsigned int dataSize):
        self.mmPhyWrite(destAddr, self.mmPhyRead(srcAddr, dataSize), dataSize)
    cdef unsigned int mmGetAbsoluteAddressForInterrupt(self, unsigned char intNum):
        cdef unsigned int posdata
        posdata = (<Mm>self.main.mm).mmPhyReadValueUnsignedDword((<unsigned short>intNum<<2))
        posdata = (((posdata>>12)&0xffff0)+(posdata&BITMASK_WORD))
        return posdata


cdef class ConfigSpace:
    def __init__(self, unsigned int csSize, object main):
        self.csSize = csSize
        self.main = main
        self.csData = <char*>malloc(self.csSize)
        if (not self.csData):
            self.main.exitError("ConfigSpace::run: not self.csData.")
            return
        self.csResetData()
        register(self.csFreeData)
    cdef void csResetData(self):
        if (self.csData):
            memset(self.csData, 0x00, self.csSize)
    cpdef csFreeData(self):
        if (self.csData):
            free(self.csData)
        self.csData = None
    cdef bytes csRead(self, unsigned int offset, unsigned int size):
        IF STRICT_CHECKS:
            if (not self.csData or not size or offset+size > self.csSize):
                self.main.exitError("ConfigSpace::csRead: not self.csData || not size || offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
                return b'\x00'*size
        return self.csData[offset:offset+size]
    cdef void csWrite(self, unsigned int offset, bytes data, unsigned int size):
        IF STRICT_CHECKS:
            if (not self.csData or not size or offset+size > self.csSize):
                self.main.exitError("ConfigSpace::csWrite: not self.csData || not size || offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
                return
        memcpy(<char*>(self.csData+offset), <char*>data, size)
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
            data &= BITMASK_BYTE
        elif (size == OP_SIZE_WORD):
            data &= BITMASK_WORD
        elif (size == OP_SIZE_DWORD):
            data &= BITMASK_DWORD
        self.csWrite(offset, data.to_bytes(length=size, byteorder="little", signed=False), size)
        return data
    cdef unsigned long int csWriteValueBE(self, unsigned int offset, unsigned long int data, unsigned char size): # Big Endian
        if (size == OP_SIZE_BYTE):
            data &= BITMASK_BYTE
        elif (size == OP_SIZE_WORD):
            data &= BITMASK_WORD
        elif (size == OP_SIZE_DWORD):
            data &= BITMASK_DWORD
        self.csWrite(offset, data.to_bytes(length=size, byteorder="big", signed=False), size)
        return data
    cdef unsigned long int csAddValue(self, unsigned int offset, unsigned long int data, unsigned char size):
        return self.csWriteValue(offset, (self.csReadValueUnsigned(offset, size)+data)&BITMASK_QWORD, size)
    cdef unsigned long int csSubValue(self, unsigned int offset, unsigned long int data, unsigned char size):
        return self.csWriteValue(offset, (self.csReadValueUnsigned(offset, size)-data)&BITMASK_QWORD, size)



