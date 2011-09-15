import registers, misc

cdef class MmArea:
    cdef public object main, mm
    cdef object mmAreaData
    cdef public unsigned long long mmBaseAddr, mmAreaSize
    def __init__(self, object mm, unsigned long long mmBaseAddr, unsigned long long mmAreaSize):
        self.mm = mm
        self.main = self.mm.main
        self.mmBaseAddr = mmBaseAddr
        self.mmAreaSize = mmAreaSize
        self.mmAreaData = bytearray(self.mmAreaSize)
    def mmAreaRead(self, unsigned long long mmPhyAddr, unsigned long long dataSize):
        cdef unsigned long long mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        return bytes(self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize])
    def mmAreaWrite(self, unsigned long long mmPhyAddr, bytes data, unsigned long long dataSize): # dataSize(type int) in bytes
        cdef unsigned long long mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize] = data
        return data



cdef class Mm:
    cdef public object main
    cdef list mmAreas
    def __init__(self, object main):
        self.main = main
        self.mmAreas = []
    def mmAddArea(self, unsigned long long mmBaseAddr, unsigned long long mmAreaSize):
        self.mmAreas.append(MmArea(self, mmBaseAddr, mmAreaSize))
    def mmDelArea(self, unsigned long long mmBaseAddr):
        for i in range(len(self.mmAreas)):
            if (mmBaseAddr == self.mmAreas[i].mmBaseAddr):
                del self.mmAreas[i]
                return True
        return False
    def mmGetArea(self, long long mmAddr, unsigned long long dataSize): # dataSize in bytes
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmBaseAddr+mmArea.mmAreaSize):
                return mmArea
        return None
    def mmGetRealAddr(self, long long mmAddr, unsigned short segId, unsigned char allowOverride=True):
        if (allowOverride and self.main.cpu.registers.segmentOverridePrefix):
            segId = self.main.cpu.registers.segmentOverridePrefix
        mmAddr = self.main.cpu.registers.segments.getRealAddr(segId, mmAddr)
        return mmAddr
    def mmPhyRead(self, long long mmAddr, unsigned long long dataSize, int ignoreFail=False): # dataSize in bytes
        mmArea = self.mmGetArea(mmAddr, dataSize)
        if (not mmArea):
            if (ignoreFail):
                return b'\x00'*dataSize
            self.main.exitError("mmPhyRead: mmArea not found! (mmAddr: {0:#10x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        return mmArea.mmAreaRead(mmAddr, dataSize)
    def mmPhyReadValue(self, long long mmAddr, unsigned long long dataSize, int signed=False): # dataSize in bytes
        cdef object data = self.mmPhyRead(mmAddr, dataSize)
        cdef long long retData = int.from_bytes(data, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=signed)
        return retData
    def mmRead(self, long long mmAddr, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyRead(mmAddr, dataSize)
    def mmReadValue(self, long long mmAddr, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, int signed=False, unsigned char allowOverride=True): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        cdef long long data = self.mmPhyReadValue(mmAddr, dataSize, signed=signed)
        return data
    def mmPhyWrite(self, long long mmAddr, bytes data, unsigned long long dataSize): # dataSize in bytes
        cdef object mmArea = self.mmGetArea(mmAddr, dataSize)
        if (not mmArea):
            self.main.exitError("mmPhyWrite: mmArea not found! (mmAddr: {0:08x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        return mmArea.mmAreaWrite(mmAddr, data, dataSize)
    def mmPhyWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize): # dataSize in bytes
        cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        data &= bitMask
        cdef object bytesData = data.to_bytes(length=dataSize, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=False)
        self.mmPhyWrite(mmAddr, bytesData, dataSize)
        return data
    def mmWrite(self, long long mmAddr, bytes data, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWrite(mmAddr, data, dataSize)
    def mmWriteValueWithOp(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, unsigned char allowOverride=True, unsigned char valueOp=misc.VALUEOP_SAVE): # dataSize in bytes
        if (valueOp == misc.VALUEOP_SAVE):
            return self.mmWriteValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == misc.VALUEOP_ADD):
            return self.mmAddValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == misc.VALUEOP_ADC):
            return self.mmAdcValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == misc.VALUEOP_SUB):
            return self.mmSubValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == misc.VALUEOP_SBB):
            return self.mmSbbValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == misc.VALUEOP_AND):
            return self.mmAndValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == misc.VALUEOP_OR):
            return self.mmOrValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
        elif (valueOp == misc.VALUEOP_XOR):
            return self.mmXorValue(mmAddr, data, dataSize, segId=segId, allowOverride=allowOverride)
    def mmWriteValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, data, dataSize)
    def mmAddValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, (self.mmPhyReadValue(mmAddr, dataSize)+data)&bitMask, dataSize)
    def mmAdcValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        cdef unsigned char withCarry = self.main.cpu.registers.getEFLAG( registers.FLAG_CF )
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, (self.mmPhyReadValue(mmAddr, dataSize)+(data+withCarry))&bitMask, dataSize)
    def mmSubValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, (self.mmPhyReadValue(mmAddr, dataSize)-data)&bitMask, dataSize)
    def mmSbbValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        cdef unsigned char withCarry = self.main.cpu.registers.getEFLAG( registers.FLAG_CF )
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, (self.mmPhyReadValue(mmAddr, dataSize)-(data+withCarry))&bitMask, dataSize)
    def mmAndValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        ###cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, self.mmPhyReadValue(mmAddr, dataSize)&data, dataSize)
    def mmOrValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        ###cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, self.mmPhyReadValue(mmAddr, dataSize)|data, dataSize)
    def mmXorValue(self, long long mmAddr, unsigned long long data, unsigned long long dataSize, unsigned short segId=registers.CPU_SEGMENT_DS, unsigned char allowOverride=True): # dataSize in bytes, data==int
        ###cdef unsigned long long bitMask = self.main.misc.getBitMask(dataSize)
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, self.mmPhyReadValue(mmAddr, dataSize)^data, dataSize)
    


cdef class ConfigSpace:
    cdef object main, csData
    cdef unsigned long long csSize
    def __init__(self, int csSize, object main):
        self.csSize = csSize
        self.main   = main
        self.csData = bytearray(self.csSize)
    def csRead(self, unsigned long long offset, unsigned long long size):
        return self.csData[offset:offset+size]
    def csWrite(self, unsigned long long offset, bytes data, unsigned long long size): # dataSize in bytes; use 'signed' only if writing 'int'
        self.csData[offset:offset+size] = data
        return size
    def csReadValue(self, unsigned long long offset, unsigned long long size, int signed=False): # dataSize in bytes
        cdef object data = self.csRead(offset, size)
        cdef long long retData = int.from_bytes(data, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=signed)
        return retData
    def csWriteValue(self, unsigned long long offset, unsigned long long data, unsigned long long size): # dataSize in bytes
        cdef object bytesData = data.to_bytes(length=size, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN)
        return self.csWrite(offset, bytesData, size)
    def csAddValue(self, unsigned long long offset, unsigned long long data, unsigned long long size): # dataSize in bytes, data==int
        return self.csWriteValue(offset, self.csReadValue(offset, size)+data, size)
    def csSubValue(self, unsigned long long offset, unsigned long long data, unsigned long long size): # dataSize in bytes, data==int
        return self.csWriteValue(offset, self.csReadValue(offset, size)-data, size)








