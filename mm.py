import registers, misc

class MmArea:
    def __init__(self, mm, mmBaseAddr, mmAreaSize):
        self.mm = mm
        self.main = self.mm.main
        self.mmBaseAddr = mmBaseAddr
        self.mmAreaSize = mmAreaSize
        self.mmAreaData = bytearray(self.mmAreaSize)
    def mmAreaRead(self, mmPhyAddr, dataSize):
        mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        return self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize]
    def mmAreaWrite(self, mmPhyAddr, data, dataSize): # dataSize(type int) in bytes
        mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize] = data
        return dataSize



class Mm:
    def __init__(self, main):
        self.main = main
        self.mmAreas = []
    def mmAddArea(self, mmBaseAddr, mmAreaSize):
        self.mmAreas.append(MmArea(self, mmBaseAddr, mmAreaSize))
    def mmDelArea(self, mmBaseAddr):
        for i in range(len(self.mmAreas)):
            if (mmBaseAddr == self.mmAreas[i].mmBaseAddr):
                del self.mmAreas[i]
                return True
        return False
    def mmGetArea(self, mmAddr, dataSize): # dataSize in bytes
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmBaseAddr+mmArea.mmAreaSize):
                return mmArea
        return None
    def mmGetRealAddr(self, mmAddr, segId, allowOverride=True):
        if (segId and not hasattr(self.main, 'cpu')):
            self.main.exitError("mmGetRealAddr: segId != 0 && no attr 'cpu' in self.main")
            return
        if (segId != 0 and segId not in registers.CPU_SEGMENTS):
            self.main.exitError("mmGetRealAddr: segId not in CPU_SEGMENTS")
            return
        #elif (segId):
        if (allowOverride and self.main.cpu.registers.segmentOverridePrefix):
            segId = self.main.cpu.registers.segmentOverridePrefix
        mmAddr = self.main.cpu.registers.segments.getRealAddr(segId, mmAddr)
        return mmAddr
    def mmPhyRead(self, mmAddr, dataSize): # dataSize in bytes
        mmArea = self.mmGetArea(mmAddr, dataSize)
        if (not mmArea):
            self.main.exitError("mmPhyRead: mmArea not found! (mmAddr: {0:#10x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        return mmArea.mmAreaRead(mmAddr, dataSize)
    def mmPhyReadValue(self, mmAddr, dataSize, signed=False): # dataSize in bytes
        data = self.mmPhyRead(mmAddr, dataSize)
        retData = int.from_bytes(data, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=signed)
        return retData
    def mmRead(self, mmAddr, dataSize, segId=registers.CPU_SEGMENT_DS, allowOverride=True): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyRead(mmAddr, dataSize)
    def mmReadValue(self, mmAddr, dataSize, segId=registers.CPU_SEGMENT_DS, signed=False, allowOverride=True): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        data = self.mmPhyReadValue(mmAddr, dataSize, signed=signed)
        return data
    def mmPhyWrite(self, mmAddr, data, dataSize): # dataSize in bytes
        mmArea = self.mmGetArea(mmAddr, dataSize)
        if (not mmArea):
            self.main.exitError("mmPhyWrite: mmArea not found! (mmAddr: {0:08x}, dataSize: {1:d})", mmAddr, dataSize)
            return
        return mmArea.mmAreaWrite(mmAddr, data, dataSize)
    def mmPhyWriteValue(self, mmAddr, data, dataSize): # dataSize in bytes
        bytesData = data.to_bytes(length=dataSize, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=False)
        return self.mmPhyWrite(mmAddr, bytesData, dataSize)
    def mmWrite(self, mmAddr, data, dataSize, segId=registers.CPU_SEGMENT_DS, allowOverride=True): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWrite(mmAddr, data, dataSize)
    def mmWriteValue(self, mmAddr, data, dataSize, segId=registers.CPU_SEGMENT_DS, allowOverride=True): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId, allowOverride=allowOverride)
        return self.mmPhyWriteValue(mmAddr, data, dataSize)
    def mmAdd(self, mmAddr, data, dataSize, segId=registers.CPU_SEGMENT_DS): # dataSize in bytes, data==int
        return self.mmWriteValue(mmAddr, self.mmReadValue(mmAddr, dataSize, segId, signed)+data, dataSize, segId=segId)
    def mmSub(self, mmAddr, data, dataSize, segId=registers.CPU_SEGMENT_DS): # dataSize in bytes, data==int
        return self.mmWriteValue(mmAddr, self.mmReadValue(mmAddr, dataSize, segId, signed)-data, dataSize, segId=segId)


class ConfigSpace:
    def __init__(self, csSize, main):
        self.csSize = csSize
        self.main   = main
        self.csData = bytearray(self.csSize)
    def csRead(self, offset, size):
        return self.csData[offset:offset+size]
    def csWrite(self, offset, data, size): # dataSize in bytes; use 'signed' only if writing 'int'
        self.csData[offset:offset+size] = data
        return size
    def csReadValue(self, offset, size, signed=False): # dataSize in bytes
        data = self.csRead(offset, size)
        retData = int.from_bytes(data, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=signed)
        return retData
    def csWriteValue(self, offset, data, size): # dataSize in bytes
        bytesData = data.to_bytes(length=size, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN)
        return self.csWrite(offset, bytesData, size)
    def csAddValue(self, offset, data, size): # dataSize in bytes, data==int
        return self.csWriteValue(offset, self.csReadValue(offset, size, signed)+data, size)
    def csSubValue(self, offset, data, size): # dataSize in bytes, data==int
        return self.csWriteValue(offset, self.csReadValue(offset, size, signed)-data, size)








