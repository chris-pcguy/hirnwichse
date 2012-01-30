
from atexit import register

include "globals.pxi"




cdef class MmArea:
    def __init__(self, Mm mmObj, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly):
        self.mm = mmObj
        self.main = self.mm.main
        self.mmBaseAddr = mmBaseAddr
        self.mmAreaSize = mmAreaSize
        self.mmEndAddr  = self.mmBaseAddr+self.mmAreaSize
        self.mmReadOnly = mmReadOnly
    cdef mmResetAreaData(self):
        if (self.mmAreaData is not None):
            memset(self.mmAreaData, 0x00, self.mmAreaSize)
    cpdef mmFreeAreaData(self):
        if (self.mmAreaData is not None):
            free(self.mmAreaData)
        self.mmAreaData = None
    cdef mmSetReadOnly(self, unsigned char mmReadOnly):
        self.mmReadOnly = mmReadOnly
    cdef bytes mmAreaRead(self, unsigned long long mmAddr, unsigned long long dataSize):
        mmAddr -= self.mmBaseAddr
        if (self.mmAreaData is None or not dataSize):
            self.main.printMsg("MmArea::mmAreaRead: self.mmAreaData is None || not dataSize.")
            raise MemoryError()
        return self.mmAreaData[mmAddr:mmAddr+dataSize]
    cdef mmAreaWrite(self, unsigned long long mmAddr, bytes data, unsigned long long dataSize):
        mmAddr -= self.mmBaseAddr
        if (self.mmAreaData is None or not dataSize):
            self.main.printMsg("MmArea::mmAreaWrite: self.mmAreaData is None || not dataSize.")
            raise MemoryError()
        if (self.mmReadOnly):
            self.main.exitError("MmArea::mmAreaWrite: mmArea is mmReadOnly, exiting...")
            return
        memcpy(<char*>(self.mmAreaData+mmAddr), <char*>data, dataSize)
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
    cdef mmAddArea(self, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly, MmArea mmAreaObject):
        cdef MmArea mmAreaObjectInstance
        mmAreaObjectInstance = <MmArea>mmAreaObject(self, mmBaseAddr, mmAreaSize, mmReadOnly)
        mmAreaObjectInstance.run()
        self.mmAreas.append(mmAreaObjectInstance)
    cdef unsigned char mmDelArea(self, unsigned long long mmBaseAddr):
        cdef unsigned short i
        for i in range(len(self.mmAreas)):
            if (mmBaseAddr == self.mmAreas[i].mmBaseAddr):
                self.mmAreas[i] = None
                del self.mmAreas[i]
                return True
        return False
    cdef MmArea mmGetSingleArea(self, long long mmAddr, unsigned long long dataSize): # dataSize in bytes
        cdef MmArea mmArea
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmEndAddr):
                return mmArea
    cdef list mmGetAreas(self, long long mmAddr, unsigned long long dataSize): # dataSize in bytes
        cdef MmArea mmArea
        cdef list foundAreas
        foundAreas = []
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmEndAddr):
                foundAreas.append(mmArea)
        return foundAreas
    cdef bytes mmPhyRead(self, long long mmAddr, unsigned long long dataSize): # dataSize in bytes
        cdef MmArea mmArea
        mmArea = self.mmGetSingleArea(mmAddr, dataSize)
        if (mmArea is None):
            self.main.exitError("mmPhyRead: mmAreas not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        return mmArea.mmAreaRead(mmAddr, dataSize)
    cdef long long mmPhyReadValueSigned(self, long long mmAddr, unsigned char dataSize):
        return int.from_bytes((<bytes>self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=True)
    cdef unsigned long long mmPhyReadValueUnsigned(self, long long mmAddr, unsigned char dataSize):
        return int.from_bytes((<bytes>self.mmPhyRead(mmAddr, dataSize)), byteorder="little", signed=False)
    cdef mmPhyWrite(self, long long mmAddr, bytes data, unsigned long long dataSize): # dataSize in bytes
        cdef MmArea mmArea
        cdef list mmAreas
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.exitError("mmPhyWrite: mmAreas not found! (mmAddr: {0:#010x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        for mmArea in mmAreas:
            mmArea.mmAreaWrite(mmAddr, data, dataSize)
    cdef unsigned long long mmPhyWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize):
        if (dataSize == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (dataSize == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (dataSize == OP_SIZE_DWORD):
            data = <unsigned long>data
        self.mmPhyWrite(mmAddr, (<bytes>data.to_bytes(length=dataSize, byteorder="little", signed=False)), dataSize)
        return data


cdef class ConfigSpace:
    def __init__(self, unsigned long csSize, object main):
        self.csSize = csSize
        self.main = main
    cdef csResetData(self):
        if (self.csData is not None):
            memset(self.csData, 0x00, self.csSize)
    cpdef csFreeData(self):
        if (self.csData is not None):
            free(self.csData)
        self.csData = None
    cdef bytes csRead(self, unsigned long offset, unsigned long size):
        if (self.csData is None or not size or offset+size > self.csSize):
            self.main.printMsg("ConfigSpace::csRead: self.csData is None || not size || offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
            raise MemoryError()
        return self.csData[offset:offset+size]
    cdef csWrite(self, unsigned long offset, bytes data, unsigned long size):
        if (self.csData is None or not size or offset+size > self.csSize):
            self.main.printMsg("ConfigSpace::csWrite: self.csData is None || not size || offset+size > self.csSize. (offset: {0:#06x}, size: {1:d})", offset, size)
            raise MemoryError()
        memcpy(<char*>(self.csData+offset), <char*>data, size)
    cdef unsigned long long csReadValueUnsigned(self, unsigned long offset, unsigned long size):
        return int.from_bytes(self.csRead(offset, size), byteorder="little", signed=False)
    cdef unsigned long long csReadValueUnsignedBE(self, unsigned long offset, unsigned long size): # Big Endian
        return int.from_bytes(self.csRead(offset, size), byteorder="big", signed=False)
    cdef long long csReadValueSigned(self, unsigned long offset, unsigned long size):
        return int.from_bytes(self.csRead(offset, size), byteorder="little", signed=True)
    cdef long long csReadValueSignedBE(self, unsigned long offset, unsigned long size): # Big Endian
        return int.from_bytes(self.csRead(offset, size), byteorder="big", signed=True)
    cdef unsigned long long csWriteValue(self, unsigned long offset, unsigned long long data, unsigned long size):
        if (size == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (size == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (size == OP_SIZE_DWORD):
            data = <unsigned long>data
        self.csWrite(offset, (<bytes>data.to_bytes(length=size, byteorder="little", signed=False)), size)
        return data
    cdef unsigned long long csWriteValueBE(self, unsigned long offset, unsigned long long data, unsigned long size): # Big Endian
        if (size == OP_SIZE_BYTE):
            data = <unsigned char>data
        elif (size == OP_SIZE_WORD):
            data = <unsigned short>data
        elif (size == OP_SIZE_DWORD):
            data = <unsigned long>data
        self.csWrite(offset, (<bytes>data.to_bytes(length=size, byteorder="big", signed=False)), size)
        return data
    cdef unsigned long long csAddValue(self, unsigned long offset, unsigned long long data, unsigned long size):
        return self.csWriteValue(offset, self.csReadValueUnsigned(offset, size)+data, size)
    cdef unsigned long long csSubValue(self, unsigned long offset, unsigned long long data, unsigned long size):
        return self.csWriteValue(offset, self.csReadValueUnsigned(offset, size)-data, size)
    cpdef run(self):
        self.csData = <char*>malloc(self.csSize)
        if (self.csData is None):
            raise MemoryError()
        self.csResetData()
        register(self.csFreeData)



