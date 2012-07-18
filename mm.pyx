
from atexit import register

include "globals.pxi"
include "cpu_globals.pxi"

DEF MM_NUMAREAS = 4096

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
        mmArea.start = start
        mmArea.end  = mmArea.start+SIZE_1MB-1
        mmArea.readOnly = readOnly
        if (mmArea.end < mmArea.start):
            self.main.exitError("Mm::mmAddArea: mem-address overflow.")
            return None
        mmArea.data = <char*>malloc(SIZE_1MB)
        if (not mmArea.data):
            self.main.exitError("Mm::mmAddArea: not mmArea.data.")
            return None
        memset(mmArea.data, 0x00, SIZE_1MB)
        mmArea.readClass  = self
        mmArea.writeClass = self
        mmArea.readHandler  = <MmAreaReadType>self.mmAreaRead
        mmArea.writeHandler = <MmAreaWriteType>self.mmAreaWrite
        return mmArea
    cdef void mmDelArea(self, unsigned int addr):
        cdef MmArea mmArea = self.mmGetArea(addr)
        if (mmArea and mmArea.data):
            free(mmArea.data)
            mmArea.data = None
        mmArea = None
    cdef MmArea mmGetArea(self, unsigned int addr):
        addr >>= 20
        if (addr >= MM_NUMAREAS):
            return None
        return self.mmAreas[addr]
    cdef list mmGetAreas(self, unsigned int mmAddr, unsigned int dataSize):
        cdef MmArea mmArea
        cdef list mmAreas
        cdef unsigned int begin, end, count, i
        mmAreas = []
        end = (mmAddr+dataSize-1) >> 20
        begin = (mmAddr) >> 20
        count = end-begin+1
        for i in range(count):
            if (begin+i >= MM_NUMAREAS):
                break
            mmArea = self.mmAreas[begin+i]
            if (not mmArea):
                continue
            mmAreas.append(mmArea)
        return mmAreas
    cdef void mmSetReadOnly(self, unsigned int addr, unsigned char readOnly):
        cdef MmArea mmArea = self.mmGetArea(addr)
        mmArea.readOnly = readOnly
    cdef bytes mmAreaRead(self, MmArea mmArea, unsigned int offset, unsigned int dataSize):
        if (not mmArea or not mmArea.data or not dataSize):
            self.main.exitError("Mm::mmAreaRead: not mmArea(.data) || not dataSize.")
            return b'\xff'*dataSize
        return mmArea.data[offset:offset+dataSize]
    cdef void mmAreaWrite(self, MmArea mmArea, unsigned int offset, char *data, unsigned int dataSize):
        if (not mmArea or mmArea.readOnly or not mmArea.data or not dataSize):
            self.main.exitError("Mm::mmAreaWrite: not mmArea(.data) || mmArea.readOnly || not dataSize.")
            return
        with nogil:
            memcpy(<char*>(mmArea.data+offset), data, dataSize)
    cdef bytes mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize):
        cdef MmArea mmArea
        cdef unsigned int tempAddr, tempSize, tempDataSize = dataSize
        cdef bytes data = bytes()
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.debug("Mm::mmPhyRead: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            return b'\xff'*dataSize
        tempSize = min(SIZE_1MB, dataSize)
        for mmArea in mmAreas:
            if (not mmArea.readClass or not mmArea.readHandler):
                self.main.debug("Mm::mmPhyRead: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
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
            self.main.exitError("Mm::mmPhyRead: tempDataSize: {0:#06x} is not zero.", tempDataSize)
            return b'\xff'*dataSize
        ## assume, that mmArea is set to the last entry in mmAreas
        if (mmAddr-1 > mmArea.end):
            self.main.exitError("Mm::mmPhyRead: mmAddr overflow")
            return b'\xff'*dataSize
        return data
    cdef signed long int mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(<bytes>(self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=True)
    cdef unsigned long int mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(<bytes>(self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=False)
    cdef void mmPhyWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize):
        cdef MmArea mmArea
        cdef list mmAreas
        cdef unsigned int tempAddr, tempSize, tempDataSize = dataSize
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.debug("Mm::mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        tempSize = min(SIZE_1MB, dataSize)
        for mmArea in mmAreas:
            if (not mmArea.writeClass or not mmArea.writeHandler):
                self.main.debug("Mm::mmPhyWrite: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
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
            self.main.exitError("Mm::mmPhyWrite: tempDataSize: {0:#06x} is not zero.", tempDataSize)
        ## assume, that mmArea is set to the last entry in mmAreas
        if (mmAddr-1 > mmArea.end):
            self.main.exitError("Mm::mmPhyWrite: mmAddr overflow")
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
        cdef unsigned short seg, offset
        cdef unsigned int posdata
        posdata = (<Mm>self.main.mm).mmPhyReadValueUnsigned((<unsigned short>intNum*4), 4)
        offset = posdata
        seg = (posdata>>16)
        posdata = (seg<<4)+offset
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



