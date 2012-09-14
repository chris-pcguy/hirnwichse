
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
        self.main = main
        self.mmAreas = []
        for i in range(MM_NUMAREAS):
            self.mmAreas.append(MmArea())
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
        mmArea.data = <char*>malloc(SIZE_1MB)
        if (mmArea.data is NULL):
            self.main.exitError("Mm::mmAddArea: not mmArea.data.")
            return None
        self.mmClearArea(mmArea, 0x00)
        mmArea.readClass  = self
        mmArea.writeClass = self
        mmArea.readHandler  = <MmAreaReadType>self.mmAreaRead
        mmArea.writeHandler = <MmAreaWriteType>self.mmAreaWrite
        return mmArea
    cdef void mmClearArea(self, MmArea mmArea, unsigned char clearByte):
        if (not mmArea.valid or mmArea.data is NULL):
            self.main.exitError("Mm::mmClearArea: not mmArea or not mmArea.data.")
            return
        memset(mmArea.data, clearByte, SIZE_1MB)
    cdef void mmDelArea(self, unsigned int addr):
        cdef MmArea mmArea = self.mmGetArea(addr)
        if (mmArea.valid and mmArea.data is not NULL):
            free(mmArea.data)
            mmArea.data = NULL
        mmArea.valid = False
    cdef MmArea mmGetArea(self, unsigned int addr):
        addr >>= 20
        if (addr >= MM_NUMAREAS):
            return None
        return self.mmAreas[addr]
    cdef list mmGetAreas(self, unsigned int mmAddr, unsigned int dataSize):
        cdef MmArea mmArea
        cdef list mmAreas
        cdef unsigned short begin, end, count, i
        mmAreas = []
        end = (mmAddr+dataSize-1) >> 20
        begin = (mmAddr) >> 20
        count = end-begin+1
        if (begin+count > MM_NUMAREAS):
            self.main.notice("Mm::mmGetAreas: begin+count >= MM_NUMAREAS")
            return mmAreas
        for i in range(count):
            mmArea = self.mmAreas[begin+i]
            if (not mmArea.valid):
                continue
            mmAreas.append(mmArea)
        return mmAreas
    cdef void mmSetReadOnly(self, unsigned int addr, unsigned char readOnly):
        cdef MmArea mmArea = self.mmGetArea(addr)
        mmArea.readOnly = readOnly
    cdef bytes mmAreaRead(self, MmArea mmArea, unsigned int offset, unsigned int dataSize):
        if (not mmArea.valid or mmArea.data is NULL or not dataSize):
            self.main.exitError("Mm::mmAreaRead: not mmArea(.data) || not dataSize. (address: {0:#010x}, dataSize: {1:d})", \
              mmArea.start+offset, dataSize)
            return b'\xff'*dataSize
        return mmArea.data[offset:offset+dataSize]
    cdef void mmAreaWrite(self, MmArea mmArea, unsigned int offset, char *data, unsigned int dataSize):
        if (not mmArea.valid or mmArea.readOnly or mmArea.data is NULL or not dataSize):
            self.main.exitError("Mm::mmAreaWrite: not mmArea(.data) || mmArea.readOnly || not dataSize. (address: {0:#010x}, dataSize: {1:d}, readOnly: {2:d})", \
              mmArea.start+offset, dataSize, mmArea.readOnly)
            return
        with nogil:
            memcpy(<char*>(mmArea.data+offset), data, dataSize)
    cdef bytes mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize):
        cdef MmArea mmArea
        cdef unsigned int tempAddr, tempSize, origMmAddr = mmAddr, tempDataSize = dataSize
        cdef bytes data = bytes()
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyRead: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", origMmAddr, dataSize)
            return b'\xff'*dataSize
        tempSize = min(SIZE_1MB, dataSize)
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyRead: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", origMmAddr, dataSize)
                return b'\xff'*dataSize
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
        ## assume, that mmArea is set to the last entry in mmAreas
        if (mmAddr-1 > mmArea.end):
            self.main.exitError("Mm::mmPhyRead: mmAddr overflow")
            return b'\xff'*dataSize
        return data
    cdef signed char mmPhyReadValueSignedByte(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef signed char data = <signed char>BITMASK_BYTE
        cdef unsigned char dataSize = OP_SIZE_BYTE
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyReadValueSignedByte: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyReadValueSignedByte: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            data = int.from_bytes(<bytes>(mmArea.readHandler(mmArea.readClass, mmArea, tempAddr, dataSize)), byteorder="little", signed=True)
            return data
        return data
    cdef signed short mmPhyReadValueSignedWord(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef signed short data = <signed short>BITMASK_WORD
        cdef unsigned char dataSize = OP_SIZE_WORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyReadValueSignedWord: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyReadValueSignedWord: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueSigned(mmAddr, dataSize)
            data = int.from_bytes(<bytes>(mmArea.readHandler(mmArea.readClass, mmArea, tempAddr, dataSize)), byteorder="little", signed=True)
            return data
        return data
    cdef signed int mmPhyReadValueSignedDword(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef signed int data = <signed int>BITMASK_DWORD
        cdef unsigned char dataSize = OP_SIZE_DWORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyReadValueSignedDword: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyReadValueSignedDword: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueSigned(mmAddr, dataSize)
            data = int.from_bytes(<bytes>(mmArea.readHandler(mmArea.readClass, mmArea, tempAddr, dataSize)), byteorder="little", signed=True)
            return data
        return data
    cdef signed long int mmPhyReadValueSignedQword(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef signed long int data = <signed long int>BITMASK_QWORD
        cdef unsigned char dataSize = OP_SIZE_QWORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyReadValueSignedQword: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyReadValueSignedQword: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueSigned(mmAddr, dataSize)
            data = int.from_bytes(<bytes>(mmArea.readHandler(mmArea.readClass, mmArea, tempAddr, dataSize)), byteorder="little", signed=True)
            return data
        return data
    cdef signed long int mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(<bytes>(self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=True)
    cdef unsigned char mmPhyReadValueUnsignedByte(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef unsigned char data = BITMASK_BYTE, dataSize = OP_SIZE_BYTE
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyReadValueUnsignedByte: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyReadValueUnsignedByte: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            data = int.from_bytes(<bytes>(mmArea.readHandler(mmArea.readClass, mmArea, tempAddr, dataSize)), byteorder="little", signed=False)
            return data
        return data
    cdef unsigned short mmPhyReadValueUnsignedWord(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef unsigned short data = BITMASK_WORD
        cdef unsigned char dataSize = OP_SIZE_WORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyReadValueUnsignedWord: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyReadValueUnsignedWord: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueUnsigned(mmAddr, dataSize)
            data = int.from_bytes(<bytes>(mmArea.readHandler(mmArea.readClass, mmArea, tempAddr, dataSize)), byteorder="little", signed=False)
            return data
        return data
    cdef unsigned int mmPhyReadValueUnsignedDword(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef unsigned int data = <unsigned int>BITMASK_DWORD
        cdef unsigned char dataSize = OP_SIZE_DWORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyReadValueUnsignedDword: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyReadValueUnsignedDword: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueUnsigned(mmAddr, dataSize)
            data = int.from_bytes(<bytes>(mmArea.readHandler(mmArea.readClass, mmArea, tempAddr, dataSize)), byteorder="little", signed=False)
            return data
        return data
    cdef unsigned long int mmPhyReadValueUnsignedQword(self, unsigned int mmAddr):
        cdef MmArea mmArea
        cdef unsigned long int data = <unsigned long int>BITMASK_QWORD
        cdef unsigned char dataSize = OP_SIZE_QWORD
        cdef unsigned int tempAddr
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyReadValueUnsignedQword: mmArea not found! (mmAddr: {0:#010x})", mmAddr)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyReadValueUnsignedQword: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyReadValueUnsigned(mmAddr, dataSize)
            data = int.from_bytes(<bytes>(mmArea.readHandler(mmArea.readClass, mmArea, tempAddr, dataSize)), byteorder="little", signed=False)
            return data
        return data
    cdef unsigned long int mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(<bytes>(self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=False)
    cdef void mmPhyWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize):
        cdef MmArea mmArea
        cdef list mmAreas
        cdef unsigned int tempAddr, tempSize, origMmAddr = mmAddr, tempDataSize = dataSize
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", origMmAddr, dataSize)
            return
        tempSize = min(SIZE_1MB, dataSize)
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyWrite: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", origMmAddr, dataSize)
                return
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
        ## assume, that mmArea is set to the last entry in mmAreas
        if (mmAddr-1 > mmArea.end):
            self.main.exitError("Mm::mmPhyWrite: mmAddr overflow")
    cdef unsigned char mmPhyWriteValueByte(self, unsigned int mmAddr, unsigned char data):
        cdef MmArea mmArea
        cdef list mmAreas
        cdef unsigned char dataSize = OP_SIZE_BYTE
        cdef unsigned int tempAddr
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyWrite: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            mmArea.writeHandler(mmArea.writeClass, mmArea, tempAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
            return data
        return data
    cdef unsigned short mmPhyWriteValueWord(self, unsigned int mmAddr, unsigned short data):
        cdef MmArea mmArea
        cdef list mmAreas
        cdef unsigned char dataSize = OP_SIZE_WORD
        cdef unsigned int tempAddr
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyWrite: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyWriteValue(mmAddr, data, dataSize)
            mmArea.writeHandler(mmArea.writeClass, mmArea, tempAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
            return data
        return data
    cdef unsigned int mmPhyWriteValueDword(self, unsigned int mmAddr, unsigned int data):
        cdef MmArea mmArea
        cdef list mmAreas
        cdef unsigned char dataSize = OP_SIZE_DWORD
        cdef unsigned int tempAddr
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyWrite: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyWriteValue(mmAddr, data, dataSize)
            mmArea.writeHandler(mmArea.writeClass, mmArea, tempAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
            return data
        return data
    cdef unsigned long int mmPhyWriteValueQword(self, unsigned int mmAddr, unsigned long int data):
        cdef MmArea mmArea
        cdef list mmAreas
        cdef unsigned char dataSize = OP_SIZE_QWORD
        cdef unsigned int tempAddr
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.notice("Mm::mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            return data
        for mmArea in mmAreas:
            if (not mmArea.valid):
                self.main.notice("Mm::mmPhyWrite: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                return data
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            if (tempAddr+dataSize > SIZE_1MB):
                return self.mmPhyWriteValue(mmAddr, data, dataSize)
            mmArea.writeHandler(mmArea.writeClass, mmArea, tempAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
            return data
        return data
    cdef unsigned long int mmPhyWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (dataSize == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (dataSize == OP_SIZE_DWORD):
            data = <unsigned int>data
        self.mmPhyWrite(mmAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
        return data
    cdef void mmPhyCopy(self, unsigned int destAddr, unsigned int srcAddr, unsigned int dataSize):
        self.mmPhyWrite(destAddr, self.mmPhyRead(srcAddr, dataSize), dataSize)
    cdef unsigned int mmGetAbsoluteAddressForInterrupt(self, unsigned char intNum):
        cdef unsigned int posdata
        posdata = (<Mm>self.main.mm).mmPhyReadValueUnsigned((<unsigned short>intNum*4), 4)
        posdata = (((posdata>>12)&0xffff0)+(<unsigned short>posdata))
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
    cdef unsigned long int csAddValue(self, unsigned int offset, unsigned long int data, unsigned char size):
        return self.csWriteValue(offset, <unsigned long int>(self.csReadValueUnsigned(offset, size)+data), size)
    cdef unsigned long int csSubValue(self, unsigned int offset, unsigned long int data, unsigned char size):
        return self.csWriteValue(offset, <unsigned long int>(self.csReadValueUnsigned(offset, size)-data), size)



