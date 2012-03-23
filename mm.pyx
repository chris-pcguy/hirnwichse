
from atexit import register

include "globals.pxi"




cdef class MmArea:
    def __init__(self, Mm mmObj, unsigned int mmBaseAddr, unsigned int mmAreaSize, unsigned char mmReadOnly):
        self.mm = mmObj
        self.main = self.mm.main
        self.mmBaseAddr = mmBaseAddr
        self.mmAreaSize = mmAreaSize
        self.mmEndAddr  = (<unsigned long int>self.mmBaseAddr+self.mmAreaSize)
        self.mmReadOnly = mmReadOnly
    cdef void mmResetAreaData(self):
        if (self.mmAreaData is not None):
            memset(self.mmAreaData, 0x00, self.mmAreaSize)
    cpdef mmFreeAreaData(self):
        if (self.mmAreaData is not None):
            free(self.mmAreaData)
        self.mmAreaData = None
    cdef void mmSetReadOnly(self, unsigned char mmReadOnly):
        self.mmReadOnly = mmReadOnly
    cdef bytes mmAreaRead(self, unsigned int mmAddr, unsigned int dataSize):
        mmAddr -= self.mmBaseAddr
        IF STRICT_CHECKS:
            if (self.mmAreaData is None or not dataSize):
                self.main.printMsg("MmArea::mmAreaRead: self.mmAreaData is None || not dataSize.")
                raise MemoryError()
        return self.mmAreaData[mmAddr:mmAddr+dataSize]
    cdef void mmAreaWrite(self, unsigned int mmAddr, char *data, unsigned int dataSize):
        mmAddr -= self.mmBaseAddr
        IF STRICT_CHECKS:
            if (self.mmAreaData is None or not dataSize):
                self.main.printMsg("MmArea::mmAreaWrite: self.mmAreaData is None || not dataSize.")
                raise MemoryError()
            if (self.mmReadOnly):
                self.main.exitError("MmArea::mmAreaWrite: mmArea is mmReadOnly, exiting...")
                return
        memcpy(<char*>(self.mmAreaData+mmAddr), data, dataSize)
    cdef void mmAreaCopy(self, unsigned int destAddr, unsigned int srcAddr, unsigned int dataSize):
        destAddr -= self.mmBaseAddr
        srcAddr  -= self.mmBaseAddr
        IF STRICT_CHECKS:
            if (self.mmAreaData is None or not dataSize):
                self.main.printMsg("MmArea::mmAreaCopy: self.mmAreaData is None || not dataSize.")
                raise MemoryError()
            if (self.mmReadOnly):
                self.main.exitError("MmArea::mmAreaCopy: mmArea is mmReadOnly, exiting...")
                return
        memmove(<char*>(self.mmAreaData+destAddr), <char*>(self.mmAreaData+srcAddr), dataSize)
    cpdef run(self):
        self.mmAreaData = <char*>malloc(self.mmAreaSize)
        if (self.mmAreaData is None):
            raise MemoryError()
        self.mmResetAreaData()
        register(self.mmFreeAreaData)


cdef class Mm:
    def __init__(self, object main):
        self.main = main
        self.mmAreas = []
    cdef void mmAddArea(self, unsigned int mmBaseAddr, unsigned int mmAreaSize, unsigned char mmReadOnly, MmArea mmAreaObject):
        cdef MmArea mmAreaObjectInstance
        mmAreaObjectInstance = <MmArea>mmAreaObject(self, mmBaseAddr, mmAreaSize, mmReadOnly)
        mmAreaObjectInstance.run()
        self.mmAreas.insert(0, mmAreaObjectInstance)
    cdef unsigned char mmDelArea(self, unsigned int mmBaseAddr):
        cdef unsigned short i
        for i in range(len(self.mmAreas)):
            if (mmBaseAddr == self.mmAreas[i].mmBaseAddr):
                self.mmAreas[i] = None
                del self.mmAreas[i]
                return True
        return False
    cdef MmArea mmGetSingleArea(self, unsigned int mmAddr, unsigned int dataSize): # dataSize in bytes
        cdef MmArea mmArea
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and (<unsigned long int>mmAddr+dataSize) <= mmArea.mmEndAddr):
                return mmArea
        return None
    cdef list mmGetAreas(self, unsigned int mmAddr, unsigned int dataSize): # dataSize in bytes
        cdef MmArea mmArea
        cdef list foundAreas
        foundAreas = []
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmEndAddr):
                foundAreas.append(mmArea)
        return foundAreas
    cdef bytes mmPhyRead(self, unsigned int mmAddr, unsigned int dataSize): # dataSize in bytes
        cdef MmArea mmArea
        mmArea = self.mmGetSingleArea(mmAddr, dataSize)
        if (mmArea is None):
            self.main.exitError("mmPhyRead: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            return <bytes>(b'\x00'*dataSize)
        return mmArea.mmAreaRead(mmAddr, dataSize)
    cdef long int mmPhyReadValueSigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(<bytes>(self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=True)
    cdef unsigned long int mmPhyReadValueUnsigned(self, unsigned int mmAddr, unsigned char dataSize):
        return int.from_bytes(<bytes>(self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=False)
    cdef void mmPhyWrite(self, unsigned int mmAddr, bytes data, unsigned int dataSize): # dataSize in bytes
        cdef MmArea mmArea
        mmArea = self.mmGetSingleArea(mmAddr, dataSize)
        if (mmArea is None):
            self.main.exitError("mmPhyWrite: mmArea not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        mmArea.mmAreaWrite(mmAddr, data, dataSize)
    cdef unsigned long int mmPhyWriteValue(self, unsigned int mmAddr, unsigned long int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (dataSize == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (dataSize == OP_SIZE_DWORD):
            data = <unsigned int>data
        self.mmPhyWrite(mmAddr, <bytes>(data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
        return data
    cdef void mmPhyCopy(self, unsigned int destAddr, unsigned int srcAddr, unsigned int dataSize): # dataSize in bytes
        cdef MmArea mmAreaDest, mmAreaSrc
        mmAreaDest = self.mmGetSingleArea(destAddr, dataSize)
        mmAreaSrc = self.mmGetSingleArea(srcAddr, dataSize)
        if (mmAreaDest is None or mmAreaSrc is None or mmAreaDest is not mmAreaSrc):
            self.mmPhyWrite(destAddr, self.mmPhyRead(srcAddr, dataSize), dataSize)
            return
        mmAreaDest.mmAreaCopy(destAddr, srcAddr, dataSize)


cdef class ConfigSpace:
    def __init__(self, unsigned int csSize, object main):
        self.csSize = csSize
        self.main = main
    cdef void csResetData(self):
        if (self.csData is not None):
            memset(self.csData, 0x00, self.csSize)
    cpdef csFreeData(self):
        if (self.csData is not None):
            free(self.csData)
        self.csData = None
    cdef bytes csRead(self, unsigned int offset, unsigned int size):
        IF STRICT_CHECKS:
            if (self.csData is None or not size or offset+size > self.csSize):
                self.main.printMsg("ConfigSpace::csRead: self.csData is None || not size || offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
                raise MemoryError()
        return self.csData[offset:offset+size]
    cdef void csWrite(self, unsigned int offset, bytes data, unsigned int size):
        IF STRICT_CHECKS:
            if (self.csData is None or not size or offset+size > self.csSize):
                self.main.printMsg("ConfigSpace::csWrite: self.csData is None || not size || offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
                raise MemoryError()
        memcpy(<char*>(self.csData+offset), <char*>data, size)
    cdef void csCopy(self, unsigned int destOffset, unsigned int srcOffset, unsigned int size):
        IF STRICT_CHECKS:
            if (self.csData is None or not size or (destOffset+size > self.csSize) or (srcOffset+size > self.csSize)):
                self.main.printMsg("ConfigSpace::csCopy: self.csData is None || not size || (destOffset+size > self.csSize) || (srcOffset+size > self.csSize). (destOffset: {0:#06x}, srcOffset: {1:#06x}, size: {2:d})", destOffset, srcOffset, size)
                raise MemoryError()
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
    cpdef run(self):
        self.csData = <char*>malloc(self.csSize)
        if (self.csData is None):
            raise MemoryError()
        self.csResetData()
        register(self.csFreeData)



