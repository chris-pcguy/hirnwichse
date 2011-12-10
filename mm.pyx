
#cimport mm
import registers, misc

include "globals.pxi"


cdef class MmArea:
    def __init__(self, object mmObj, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly):
        self.mm = mmObj
        self.main = self.mm.main
        self.mmBaseAddr = mmBaseAddr
        self.mmAreaSize = mmAreaSize
        self.mmEndAddr  = self.mmBaseAddr+self.mmAreaSize
        self.mmReadOnly = mmReadOnly
        self.mmAreaData = bytearray(self.mmAreaSize)
    cpdef mmSetReadOnly(self, unsigned char mmReadOnly):
        self.mmReadOnly = mmReadOnly
    cpdef bytes mmAreaRead(self, unsigned long long mmAddr, unsigned long long dataSize):
        mmAddr -= self.mmBaseAddr
        return bytes(self.mmAreaData[mmAddr:mmAddr+dataSize])
    cpdef mmAreaWrite(self, unsigned long long mmAddr, bytes data, unsigned long long dataSize):
        if (self.mmReadOnly):
            self.main.exitError("MmArea::mmAreaWrite: mmArea is mmReadOnly, exiting...")
            return
        IF STRICT_CHECKS == 1:
            if (len(data) != dataSize):
                self.main.exitError("MmArea::mmAreaWrite: len(data): {0:#04x} != dataSize: {1:#04x}", len(data), dataSize)
                return
        mmAddr -= self.mmBaseAddr
        self.mmAreaData[mmAddr:mmAddr+dataSize] = data



cdef class Mm:
    def __init__(self, object main):
        self.main = main
        self.mmAreas = []
    cpdef mmAddArea(self, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly, object mmAreaObject):
        self.mmAreas.append(mmAreaObject(self, mmBaseAddr, mmAreaSize, mmReadOnly))
    cpdef unsigned char mmDelArea(self, unsigned long long mmBaseAddr):
        cdef unsigned short i
        for i in range(len(self.mmAreas)):
            if (mmBaseAddr == self.mmAreas[i].mmBaseAddr):
                del self.mmAreas[i]
                return True
        return False
    cpdef object mmGetSingleArea(self, long long mmAddr, unsigned long long dataSize): # dataSize in bytes
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmEndAddr):
                return mmArea
    cpdef list mmGetAreas(self, long long mmAddr, unsigned long long dataSize): # dataSize in bytes
        cdef list foundAreas = []
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmEndAddr):
                foundAreas.append(mmArea)
        return foundAreas
    cpdef unsigned long long mmGetRealAddr(self, long long mmAddr, unsigned short segId, unsigned char allowOverride):
        if (allowOverride and self.main.cpu.registers.segmentOverridePrefix):
            segId = self.main.cpu.registers.segmentOverridePrefix
        mmAddr = self.main.cpu.registers.segments.getRealAddr(segId, mmAddr)
        return mmAddr
    cpdef bytes mmPhyRead(self, long long mmAddr, unsigned long long dataSize): # dataSize in bytes
        cpdef object mmArea
        mmArea = self.mmGetSingleArea(mmAddr, dataSize)
        if (not mmArea):
            self.main.exitError("mmPhyRead: mmAreas not found! (mmAddr: {0:#10x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        return mmArea.mmAreaRead(mmAddr, dataSize)
    cpdef mmPhyReadValue(self, long long mmAddr, unsigned long long dataSize, unsigned char signed): # dataSize in bytes
        cdef bytes data = self.mmPhyRead(mmAddr, dataSize)
        cdef long long retDataSigned
        cdef unsigned long long retDataUnsigned
        if (signed):
            retData = int.from_bytes(data, byteorder="little", signed=signed)
            return retData
        else:
            retDataUnsigned = int.from_bytes(data, byteorder="little", signed=signed)
            return retDataUnsigned
    cpdef bytes mmRead(self, long long mmAddr, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride): # dataSize in bytes
        #self.main.cpu.registers.checkMemAccessRights(segId, False) # TODO
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        return self.mmPhyRead(mmAddr, dataSize)
    cpdef mmReadValue(self, long long mmAddr, unsigned long long dataSize, unsigned short segId, unsigned char signed, unsigned char allowOverride): # dataSize in bytes
        cdef long long valueSigned
        cdef unsigned long long valueUnsigned
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        if (signed):
            valueSigned = self.mmPhyReadValue(mmAddr, dataSize, signed)
            return valueSigned
        else:
            valueUnsigned = self.mmPhyReadValue(mmAddr, dataSize, signed)
            return valueUnsigned
    cpdef mmPhyWrite(self, long long mmAddr, bytes data, unsigned long long dataSize): # dataSize in bytes
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.exitError("mmPhyWrite: mmAreas not found! (mmAddr: {0:08x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        for mmArea in mmAreas:
            mmArea.mmAreaWrite(mmAddr, data, dataSize)
    cpdef unsigned long long mmPhyWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize):
        cdef bytes bytesData
        data &= self.main.misc.getBitMaskFF(dataSize)
        bytesData = data.to_bytes(length=dataSize, byteorder="little")
        self.mmPhyWrite(mmAddr, bytesData, dataSize)
        return data
    cpdef mmWrite(self, long long mmAddr, bytes data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride): # dataSize in bytes
        #self.main.cpu.registers.checkMemAccessRights(segId, True) # TODO
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        self.mmPhyWrite(mmAddr, data, dataSize)
    cpdef unsigned long long mmWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride)
        data &= self.main.misc.getBitMaskFF(dataSize)
        return self.mmPhyWriteValue(mmAddr, data, dataSize)
    cpdef unsigned long long mmWriteValueWithOp(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId, unsigned char allowOverride, unsigned char valueOp): # dataSize in bytes
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
            oldData = self.mmReadValue(mmAddr, dataSize, segId, False, allowOverride)
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
        self.csData = bytearray(self.csSize)
    cpdef bytes csRead(self, unsigned long offset, unsigned long size):
        return bytes(self.csData[offset:offset+size])
    cpdef csWrite(self, unsigned long offset, bytes data, unsigned long size): # dataSize in bytes; use 'signed' only if writing 'int'
        self.csData[offset:offset+size] = data
    cpdef unsigned long long csReadValue(self, unsigned long offset, unsigned long size): # dataSize in bytes
        cdef bytes data = self.csRead(offset, size)
        cdef unsigned long retData = int.from_bytes(data, byteorder="little", signed=False)
        return retData
    cpdef unsigned long long csWriteValue(self, unsigned long offset, unsigned long long data, unsigned long size): # dataSize in bytes
        cdef bytes bytesData = data.to_bytes(length=size, byteorder="little")
        self.csWrite(offset, bytesData, size)
        return data
    cpdef unsigned long long csAddValue(self, unsigned long offset, unsigned long long data, unsigned long size): # dataSize in bytes, data==int
        return self.csWriteValue(offset, self.csReadValue(offset, size)+data, size)
    cpdef unsigned long long csSubValue(self, unsigned long offset, unsigned long long data, unsigned long size): # dataSize in bytes, data==int
        return self.csWriteValue(offset, self.csReadValue(offset, size)-data, size)








