
from atexit import register
from misc import ChemuException

include "globals.pxi"
include "cpu_globals.pxi"

DEF MM_NUMAREAS = 4096

cdef class Mm:
    def __init__(self, object main, unsigned int memSize):
        cdef unsigned int i
        self.main = main
        self.memSize = memSize
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
            raise SystemExit()
        mmArea.data = <char*>malloc(SIZE_1MB)
        if (mmArea.data is None):
            self.main.exitError("Mm::mmAddArea: mmArea.data is None.")
            raise SystemExit()
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
            if (mmArea is None):
                continue
            mmAreas.append(mmArea)
        return mmAreas
    cdef void mmSetReadOnly(self, unsigned int addr, unsigned char readOnly):
        cdef MmArea mmArea = self.mmGetArea(addr)
        mmArea.readOnly = readOnly
    cdef bytes mmAreaRead(self, MmArea mmArea, unsigned int offset, unsigned int dataSize):
        IF STRICT_CHECKS:
            if (mmArea is None or mmArea.data is None or not dataSize):
                self.main.exitError("Mm::mmAreaRead: mmArea(.data) is None || not dataSize.")
                raise SystemExit()
        return mmArea.data[offset:offset+dataSize]
    cdef void mmAreaWrite(self, MmArea mmArea, unsigned int offset, char *data, unsigned int dataSize):
        IF STRICT_CHECKS:
            if (mmArea is None or mmArea.readOnly or mmArea.data is None or not dataSize):
                self.main.exitError("Mm::mmAreaWrite: mmArea(.data) is None || mmArea.readOnly || not dataSize.")
                raise SystemExit()
        with nogil:
            memcpy(<char*>(mmArea.data+offset), data, dataSize)
    cpdef object mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize):
        cdef MmArea mmArea
        cdef list mmAreas
        cdef bytes data
        cdef unsigned int tempAddr, tempSize, tempDataSize
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.debug("Mm::mmPhyRead: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            #raise ChemuException(CPU_EXCEPTION_GP, 0)
            return b'\xff'*dataSize
        data = bytes()
        tempDataSize = dataSize
        tempSize = min(SIZE_1MB, dataSize)
        for mmArea in mmAreas:
            if (not mmArea.readClass or not mmArea.readHandler):
                self.main.debug("Mm::mmPhyRead: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                #raise ChemuException(CPU_EXCEPTION_GP, 0)
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
            self.main.debug("Mm::mmPhyRead: tempDataSize: {0:#06x} is not zero.", tempDataSize)
            raise ChemuException(CPU_EXCEPTION_GP, 0)
        ## assume, that mmArea is set to the last entry in mmAreas
        if (mmAddr-1 > mmArea.end):
            self.main.notice("Mm::mmPhyRead: mmAddr overflow")
            raise ChemuException(CPU_EXCEPTION_GP, 0)
        return data
    cpdef object mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(<bytes>(self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=True)
    cpdef object mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(<bytes>(self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=False)
    cpdef object mmPhyWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize):
        cdef MmArea mmArea
        cdef list mmAreas
        cdef unsigned int tempAddr, tempSize, tempDataSize
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.debug("Mm::mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            #raise ChemuException(CPU_EXCEPTION_GP, 0)
            return
        tempDataSize = dataSize
        tempSize = min(SIZE_1MB, dataSize)
        for mmArea in mmAreas:
            if (not mmArea.writeClass or not mmArea.writeHandler):
                self.main.debug("Mm::mmPhyWrite: mmArea not found! #2 (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
                #raise ChemuException(CPU_EXCEPTION_GP, 0)
                return
            tempAddr = (mmAddr-mmArea.start)&SIZE_1MB_MASK
            tempSize = min(tempSize, tempDataSize)
            if (tempAddr+tempSize > SIZE_1MB):
                tempSize = min(SIZE_1MB-tempAddr, tempDataSize)
            mmArea.writeHandler(mmArea.writeClass, mmArea, tempAddr, data, tempSize)
            mmAddr += tempSize
            tempDataSize -= tempSize
            tempSize = dataSize-tempSize
        ## assume, that mmArea is set to the last entry in mmAreas
        if (mmAddr-1 > mmArea.end):
            self.main.notice("Mm::mmPhyWrite: mmAddr overflow")
            raise ChemuException(CPU_EXCEPTION_GP, 0)
    cpdef object mmPhyWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (dataSize == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (dataSize == OP_SIZE_DWORD):
            data = <unsigned int>data
        self.mmPhyWrite(mmAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
        return data
    cpdef object mmPhyCopy(self, unsigned int destAddr, unsigned int srcAddr, unsigned int dataSize):
        self.mmPhyWrite(destAddr, self.mmPhyRead(srcAddr, dataSize), dataSize)
    cdef unsigned int mmGetAbsoluteAddressForInterrupt(self, unsigned char intNum):
        cdef unsigned short seg, offset
        cdef unsigned int posdata
        posdata = (<Mm>self.main.mm).mmPhyReadValueUnsigned((intNum*4), 4)
        offset = posdata&BITMASK_WORD
        seg = (posdata>>16)&BITMASK_WORD
        posdata = (seg<<4)+offset
        return posdata


cdef class ConfigSpace:
    def __init__(self, unsigned int csSize, object main):
        self.csSize = csSize
        self.main = main
        self.csData = <char*>malloc(self.csSize)
        if (self.csData is None):
            self.main.exitError("ConfigSpace::run: self.csData is None.")
            raise SystemExit()
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
            if (self.csData is None or not size or offset+size > self.csSize):
                self.main.exitError("ConfigSpace::csRead: self.csData is None || not size || offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
                raise SystemExit()
        return self.csData[offset:offset+size]
    cdef void csWrite(self, unsigned int offset, bytes data, unsigned int size):
        IF STRICT_CHECKS:
            if (self.csData is None or not size or offset+size > self.csSize):
                self.main.exitError("ConfigSpace::csWrite: self.csData is None || not size || offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
                raise SystemExit()
        memcpy(<char*>(self.csData+offset), <char*>data, size)
    cdef void csCopy(self, unsigned int destOffset, unsigned int srcOffset, unsigned int size):
        IF STRICT_CHECKS:
            if (self.csData is None or not size or (destOffset+size > self.csSize) or (srcOffset+size > self.csSize)):
                self.main.exitError("ConfigSpace::csCopy: self.csData is None || not size || (destOffset+size > self.csSize) || (srcOffset+size > self.csSize). (destOffset: {0:#06x}, srcOffset: {1:#06x}, size: {2:d})", destOffset, srcOffset, size)
                raise SystemExit()
        memcpy(<char*>(self.csData+destOffset), <char*>(self.csData+srcOffset), size)
    cdef unsigned long int csReadValueUnsigned(self, unsigned int offset, unsigned char size):
        return int.from_bytes(self.csRead(offset, size), byteorder="little", signed=False)
    cdef unsigned long int csReadValueUnsignedBE(self, unsigned int offset, unsigned char size): # Big Endian
        return int.from_bytes(self.csRead(offset, size), byteorder="big", signed=False)
    cdef long int csReadValueSigned(self, unsigned int offset, unsigned char size):
        return int.from_bytes(self.csRead(offset, size), byteorder="little", signed=True)
    cdef long int csReadValueSignedBE(self, unsigned int offset, unsigned char size): # Big Endian
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



