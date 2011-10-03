import registers, misc

cimport mm

include "globals.pxi"


cdef class MmArea:
    def __init__(self, object mmObj, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly):
        self.mm = mmObj
        self.main = self.mm.main
        self.mmBaseAddr = mmBaseAddr
        self.mmAreaSize = mmAreaSize
        self.mmReadOnly = mmReadOnly
        self.mmAreaData = bytearray(self.mmAreaSize)
    cpdef public mmSetReadOnly(self, unsigned char mmReadOnly):
        self.mmReadOnly = mmReadOnly
    cpdef public bytes mmAreaRead(self, unsigned long long mmPhyAddr, unsigned long long dataSize):
        cdef unsigned long long mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        return bytes(self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize])
    cpdef public mmAreaWrite(self, unsigned long long mmPhyAddr, bytes data, unsigned long long dataSize): # dataSize(type int) in bytes
        if (self.mmReadOnly):
            self.main.exitError("MmArea::mmAreaWrite: mmArea is mmReadOnly, exiting...")
            return
        #if (len(data) != dataSize):
        #    self.main.exitError("MmArea::mmAreaWrite: len(data): {0:#04x} != dataSize: {1:#04x}", len(data), dataSize)
        #    return
        cdef unsigned long long mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize] = data
        ###return data



cdef class Mm:
    def __init__(self, object main):
        self.main = main
        self.mmAreas = []
    cpdef public mmAddArea(self, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly=False, object mmAreaObject=MmArea):
        self.mmAreas.append(mmAreaObject(self, mmBaseAddr, mmAreaSize, mmReadOnly=mmReadOnly))
    cpdef public unsigned char mmDelArea(self, unsigned long long mmBaseAddr):
        for i in range(len(self.mmAreas)):
            if (mmBaseAddr == self.mmAreas[i].mmBaseAddr):
                del self.mmAreas[i]
                return True
        return False
    cpdef public object mmGetSingleArea(self, long long mmAddr, unsigned long long dataSize): # dataSize in bytes
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmBaseAddr+mmArea.mmAreaSize):
                return mmArea
    cpdef public list mmGetAreas(self, long long mmAddr, unsigned long long dataSize): # dataSize in bytes
        cdef list foundAreas = []
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmBaseAddr+mmArea.mmAreaSize):
                foundAreas.append(mmArea)
        return foundAreas
    cpdef public unsigned long long mmGetRealAddr(self, long long mmAddr, unsigned short segId, unsigned char allowOverride=True):
        if (allowOverride and self.main.cpu.registers.segmentOverridePrefix):
            segId = self.main.cpu.registers.segmentOverridePrefix
        mmAddr = self.main.cpu.registers.segments.getRealAddr(segId, mmAddr)
        return mmAddr
    cpdef public bytes mmPhyRead(self, long long mmAddr, unsigned long long dataSize, int ignoreFail=False): # dataSize in bytes
        cdef object mmArea
        mmArea = self.mmGetSingleArea(mmAddr, dataSize)
        if (not mmArea):
            if (ignoreFail):
                return b'\x00'*dataSize
            self.main.exitError("mmPhyRead: mmAreas not found! (mmAddr: {0:#10x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        return mmArea.mmAreaRead(mmAddr, dataSize)
    cpdef public long long mmPhyReadValue(self, long long mmAddr, unsigned long long dataSize, int signed=False): # dataSize in bytes
        cdef object data = self.mmPhyRead(mmAddr, dataSize)
        cdef long long retDataSigned
        cdef unsigned long long retDataUnsigned
        if (signed):
            retData = int.from_bytes(data, byteorder="little", signed=signed)
            return retData
        else:
            retDataUnsigned = int.from_bytes(data, byteorder="little", signed=signed)
            return retDataUnsigned
    cpdef public bytes mmRead(self, long long mmAddr, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes
        self.main.cpu.registers.checkMemAccessRights(segId, False)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyRead(mmAddr, dataSize)
    cpdef public long long mmReadValue(self, long long mmAddr, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, int signed=False, unsigned char allowOverride=True): # dataSize in bytes
        cdef long long valueSigned
        cdef unsigned long long valueUnsigned
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        if (signed):
            valueSigned = self.mmPhyReadValue(mmAddr, dataSize, signed=signed)
            return valueSigned
        else:
            valueUnsigned = self.mmPhyReadValue(mmAddr, dataSize, signed=signed)
            return valueUnsigned
    cpdef public mmPhyWrite(self, long long mmAddr, bytes data, unsigned long long dataSize): # dataSize in bytes
        cdef list mmAreas = self.mmGetAreas(mmAddr, dataSize)
        if (not mmAreas):
            self.main.exitError("mmPhyWrite: mmAreas not found! (mmAddr: {0:08x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        for mmArea in mmAreas:
            mmArea.mmAreaWrite(mmAddr, data, dataSize)
    cpdef public unsigned long long mmPhyWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize): # dataSize in bytes
        cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        data &= bitMask
        cdef object bytesData = data.to_bytes(length=dataSize, byteorder="little")
        self.mmPhyWrite(mmAddr, bytesData, dataSize)
        return data
    cpdef public mmWrite(self, long long mmAddr, bytes data, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes
        self.main.cpu.registers.checkMemAccessRights(segId, True)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        self.mmPhyWrite(mmAddr, data, dataSize)
    cpdef public unsigned long long mmWriteValueWithOp(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, unsigned char allowOverride=True, unsigned char valueOp=VALUEOP_SAVE): # dataSize in bytes
        if (valueOp == VALUEOP_SAVE):
            return self.mmWriteValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == VALUEOP_ADD):
            return self.mmAddValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == VALUEOP_ADC):
            return self.mmAdcValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == VALUEOP_SUB):
            return self.mmSubValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == VALUEOP_SBB):
            return self.mmSbbValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == VALUEOP_AND):
            return self.mmAndValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == VALUEOP_OR):
            return self.mmOrValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == VALUEOP_XOR):
            return self.mmXorValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
    cpdef public unsigned long long mmWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, data, dataSize)
    cpdef public unsigned long long mmAddValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, (self.mmPhyReadValue(mmAddr, dataSize)+data)&bitMask, dataSize)
    cpdef public unsigned long long mmAdcValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        cdef unsigned char withCarry = self.main.cpu.registers.getEFLAG( FLAG_CF )
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, (self.mmPhyReadValue(mmAddr, dataSize)+(data+withCarry))&bitMask, dataSize)
    cpdef public unsigned long long mmSubValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, (self.mmPhyReadValue(mmAddr, dataSize)-data)&bitMask, dataSize)
    cpdef public unsigned long long mmSbbValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        cdef unsigned char withCarry = self.main.cpu.registers.getEFLAG( FLAG_CF )
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, (self.mmPhyReadValue(mmAddr, dataSize)-(data+withCarry))&bitMask, dataSize)
    cpdef public unsigned long long mmAndValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, self.mmPhyReadValue(mmAddr, dataSize)&data, dataSize)
    cpdef public unsigned long long mmOrValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, self.mmPhyReadValue(mmAddr, dataSize)|data, dataSize)
    cpdef public unsigned long long mmXorValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, self.mmPhyReadValue(mmAddr, dataSize)^data, dataSize)
    


cdef class ConfigSpace:
    def __init__(self, int csSize, object main):
        self.csSize = csSize
        self.main   = main
        self.csData = bytearray(self.csSize)
    cpdef public bytes csRead(self, unsigned long long offset, unsigned long long size):
        return bytes(self.csData[offset:offset+size])
    cpdef public csWrite(self, unsigned long long offset, bytes data, unsigned long long size): # dataSize in bytes; use 'signed' only if writing 'int'
        self.csData[offset:offset+size] = data
        ##return size
    cpdef public long long csReadValue(self, unsigned long long offset, unsigned long long size, int signed=False): # dataSize in bytes
        cdef object data = self.csRead(offset, size)
        cdef long long retData = int.from_bytes(data, byteorder="little", signed=signed)
        return retData
    cpdef public unsigned long long csWriteValue(self, unsigned long long offset, unsigned long long data, unsigned long long size): # dataSize in bytes
        cdef object bytesData = data.to_bytes(length=size, byteorder="little")
        self.csWrite(offset, bytesData, size)
        return data
    cpdef public unsigned long long csAddValue(self, unsigned long long offset, unsigned long long data, unsigned long long size): # dataSize in bytes, data==int
        return self.csWriteValue(offset, self.csReadValue(offset, size)+data, size)
    cpdef public unsigned long long csSubValue(self, unsigned long long offset, unsigned long long data, unsigned long long size): # dataSize in bytes, data==int
        return self.csWriteValue(offset, self.csReadValue(offset, size)-data, size)








