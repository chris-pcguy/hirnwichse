
import misc, atexit
from libc.stdlib cimport calloc, malloc, free
from libc.string cimport strncpy, memcpy, memset

include "globals.pxi"


cdef class MmArea:
    def __init__(self, object mmObj, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly):
        self.mm = mmObj
        self.main = self.mm.main
        self.mmBaseAddr = mmBaseAddr
        self.mmAreaSize = mmAreaSize
        self.mmEndAddr  = self.mmBaseAddr+self.mmAreaSize
        self.mmReadOnly = mmReadOnly
    cpdef mmFreeAreaData(self):
        if (self.mmAreaData):
            free(self.mmAreaData)
        self.mmAreaData = None
    cdef mmSetReadOnly(self, unsigned char mmReadOnly):
        self.mmReadOnly = mmReadOnly
    cdef bytes mmAreaRead(self, unsigned long long mmAddr, unsigned long long dataSize):
        if (not self.mmAreaData):
            raise MemoryError()
        mmAddr -= self.mmBaseAddr
        return bytes(self.mmAreaData[mmAddr:mmAddr+dataSize])
    cdef mmAreaWrite(self, unsigned long long mmAddr, bytes data, unsigned long long dataSize):
        cdef char *tempAddr
        if (not self.mmAreaData):
            raise MemoryError()
        if (self.mmReadOnly):
            self.main.exitError("MmArea::mmAreaWrite: mmArea is mmReadOnly, exiting...")
            return
        mmAddr -= self.mmBaseAddr
        tempAddr = <char*>(self.mmAreaData+mmAddr)
        #self.mmAreaData[mmAddr:mmAddr+dataSize] = data
        #strncpy(self.mmAreaData[mmAddr:mmAddr+dataSize], <char*>data, dataSize)
        memcpy(<char*>tempAddr, <char*>data, dataSize)
    cpdef run(self):
        #self.mmAreaData = <char*>malloc(self.mmAreaSize)
        self.mmAreaData = <char*>calloc(self.mmAreaSize, 1)
        if (not self.mmAreaData):
            raise MemoryError()
        atexit.register(self.mmFreeAreaData)


cdef class Mm:
    def __init__(self, object main):
        self.main = main
        self.mmAreas = []
    cdef mmAddArea(self, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly, MmArea mmAreaObject):
        cdef MmArea mmAreaObjectInstance
        mmAreaObjectInstance = <MmArea>mmAreaObject(self, mmBaseAddr, mmAreaSize, mmReadOnly)
        mmAreaObjectInstance.run()
        self.mmAreas.append(mmAreaObjectInstance)
    cpdef unsigned char mmDelArea(self, unsigned long long mmBaseAddr):
        cdef unsigned short i
        for i in range(len(self.mmAreas)):
            if (mmBaseAddr == self.mmAreas[i].mmBaseAddr):
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
    cdef unsigned long long mmGetRealAddr(self, long long mmAddr, unsigned short segId, unsigned char allowOverride):
        if (allowOverride and self.main.cpu.registers.segmentOverridePrefix):
            segId = self.main.cpu.registers.segmentOverridePrefix
        mmAddr = self.main.cpu.registers.segments.getRealAddr(segId, mmAddr)
        return mmAddr
    cdef bytes mmPhyRead(self, long long mmAddr, unsigned long long dataSize): # dataSize in bytes
        cdef MmArea mmArea
        mmArea = self.mmGetSingleArea(mmAddr, dataSize)
        if (not mmArea):
            self.main.exitError("mmPhyRead: mmAreas not found! (mmAddr: {0:#10x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        return mmArea.mmAreaRead(mmAddr, dataSize)
    cdef bytes mmRead(self, long long mmAddr, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride): # dataSize in bytes
        #self.main.cpu.registers.checkMemAccessRights(segId, False) # TODO
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return self.mmPhyRead(mmAddr, dataSize)
    cdef long long mmPhyReadValueSigned(self, long long mmAddr, unsigned char dataSize):
        cdef bytes data
        data = self.mmPhyRead(mmAddr, dataSize)
        return int.from_bytes(data, byteorder="little", signed=True)
    cdef unsigned long long mmPhyReadValueUnsigned(self, long long mmAddr, unsigned char dataSize):
        cdef bytes data
        data = self.mmPhyRead(mmAddr, dataSize)
        return int.from_bytes(data, byteorder="little", signed=False)
    cdef long long mmReadValueSigned(self, long long mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride):
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return self.mmPhyReadValueSigned(mmAddr, dataSize)
    cdef unsigned long long mmReadValueUnsigned(self, long long mmAddr, unsigned char dataSize, unsigned short segId, unsigned char allowOverride):
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return self.mmPhyReadValueUnsigned(mmAddr, dataSize)
    cdef mmPhyWrite(self, long long mmAddr, bytes data, unsigned long long dataSize): # dataSize in bytes
        cdef MmArea mmArea
        cdef list mmAreas
        mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.exitError("mmPhyWrite: mmAreas not found! (mmAddr: {0:08x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        for mmArea in mmAreas:
            mmArea.mmAreaWrite(mmAddr, data, dataSize)
    cdef unsigned long long mmPhyWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize):
        cdef bytes bytesData
        data &= self.main.misc.getBitMaskFF(dataSize)
        bytesData = data.to_bytes(length=dataSize, byteorder="little")
        self.mmPhyWrite(mmAddr, bytesData, dataSize)
        return data
    cdef mmWrite(self, long long mmAddr, bytes data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride): # dataSize in bytes
        #self.main.cpu.registers.checkMemAccessRights(segId, True) # TODO
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        self.mmPhyWrite(mmAddr, data, dataSize)
    cdef unsigned long long mmWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        data &= self.main.misc.getBitMaskFF(dataSize)
        return self.mmPhyWriteValue(mmAddr, data, dataSize)
    cdef unsigned long long mmWriteValueWithOp(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride, unsigned char valueOp): # dataSize in bytes
        cdef unsigned char carryOn
        cdef unsigned long long oldData, bitMask
        bitMask = self.main.misc.getBitMaskFF(dataSize)
        if (valueOp == OPCODE_SAVE):
            return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
        elif (valueOp == OPCODE_NEG):
            data = (-data)&bitMask
            return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
        elif (valueOp == OPCODE_NOT):
            data = (~data)&bitMask
            return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
        else:
            oldData = self.mmReadValueUnsigned(mmAddr, dataSize, segId, allowOverride)
            if (valueOp == OPCODE_ADD):
                data = (oldData+data)&bitMask
                return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
            elif (valueOp in (OPCODE_ADC, OPCODE_SBB)):
                carryOn = self.main.cpu.registers.getEFLAG( FLAG_CF )!=0
                if (valueOp == OPCODE_ADC):
                    data = (oldData+(data+carryOn))&bitMask
                    return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
                elif (valueOp == OPCODE_SBB):
                    data = (oldData-(data+carryOn))&bitMask
                    return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
                else:
                    self.main.exitError("Mm::mmWriteValueWithOp: unknown valueOp. ({0:d})", valueOp)
            elif (valueOp == OPCODE_SUB):
                data = (oldData-data)&bitMask
                return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
            elif (valueOp == OPCODE_AND):
                data = (oldData&data)&bitMask
                return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
            elif (valueOp == OPCODE_OR):
                data = (oldData|data)&bitMask
                return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
            elif (valueOp == OPCODE_XOR):
                data = (oldData^data)&bitMask
                return self.mmWriteValue(mmAddr, data, dataSize, segId, allowOverride)
            else:
                self.main.exitError("Mm::mmWriteValueWithOp: unknown valueOp. ({0:d})", valueOp)
            return 0


cdef class ConfigSpace:
    def __init__(self, unsigned long csSize):
        self.csSize = csSize
    cpdef csResetData(self):
        if (self.csData):
            memset(self.csData, 0, self.csSize)
    cpdef csFreeData(self):
        if (self.csData):
            free(self.csData)
        self.csData = None
    cdef bytes csRead(self, unsigned long offset, unsigned long size):
        if (not self.csData):
            raise MemoryError()
        return bytes(self.csData[offset:offset+size])
    cdef csWrite(self, unsigned long offset, bytes data, unsigned long size):
        cdef char *tempAddr
        if (not self.csData):
            raise MemoryError()
        tempAddr = <char*>(self.csData+offset)
        ####self.csData[offset:offset+size] = data
        memcpy(<char*>tempAddr, <char*>data, size)
    cdef unsigned long long csReadValue(self, unsigned long offset, unsigned long size, unsigned char signed):
        cdef bytes data = self.csRead(offset, size)
        cdef unsigned long retData = int.from_bytes(data, byteorder="little", signed=signed)
        return retData
    cdef unsigned long long csReadValueBE(self, unsigned long offset, unsigned long size, unsigned char signed): # Big Endian
        cdef bytes data = self.csRead(offset, size)
        cdef unsigned long retData = int.from_bytes(data, byteorder="big", signed=signed)
        return retData
    cdef unsigned long long csWriteValue(self, unsigned long offset, unsigned long long data, unsigned long size):
        cdef bytes bytesData = data.to_bytes(length=size, byteorder="little")
        self.csWrite(offset, bytesData, size)
        return data
    cdef unsigned long long csWriteValueBE(self, unsigned long offset, unsigned long long data, unsigned long size): # Big Endian
        cdef bytes bytesData = data.to_bytes(length=size, byteorder="big")
        self.csWrite(offset, bytesData, size)
        return data
    cdef unsigned long long csAddValue(self, unsigned long offset, unsigned long long data, unsigned long size):
        return self.csWriteValue(offset, self.csReadValue(offset, size, False)+data, size)
    cdef unsigned long long csSubValue(self, unsigned long offset, unsigned long long data, unsigned long size):
        return self.csWriteValue(offset, self.csReadValue(offset, size, False)-data, size)
    cpdef run(self):
        self.csData = <char*>calloc(self.csSize, 1)
        if (not self.csData):
            raise MemoryError()
        atexit.register(self.csFreeData)



