import registers, misc

class MmArea:
    def __init__(self, mm, long mmBaseAddr, long mmAreaSize):
        self.mm = mm
        self.main = self.mm.main
        self.mmBaseAddr = mmBaseAddr
        self.mmAreaSize = mmAreaSize
        self.mmAreaData = bytearray(self.mmAreaSize)
    def mmAreaRead(self, long mmPhyAddr, long dataSize):
        cdef long mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        return self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize]
    def mmAreaWrite(self, long mmPhyAddr, data, long dataSize, int signedValue=False): # dataSize in bytes; use 'signedValue' only if writing 'int'
        cdef long mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        cdef long realDataSize = 0
        if (isinstance(data, int)):
            data = data.to_bytes(length=dataSize, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=signedValue)
        realDataSize = len(data)
        if (realDataSize != dataSize):
            self.main.exitError("tried write to {0:#x} with invalid dataSize. (realDataSize: {1:d}, wrongDataSize: {2:d})", mmPhyAddr, realDataSize, dataSize)
            return 0
        self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize] = data
        return dataSize



class Mm:
    def __init__(self, main):
        self.main = main
        self.mmAreas = []
    def mmAddArea(self, long mmBaseAddr, long mmAreaSize):
        self.mmAreas.append(MmArea(self, mmBaseAddr, mmAreaSize))
    def mmDelArea(self, long mmBaseAddr):
        for i in range(len(self.mmAreas)):
            if (mmBaseAddr == self.mmAreas[i].mmBaseAddr):
                del self.mmAreas[i]
                return True
        return False
    def mmGetArea(self, long mmAddr, long dataSize): # dataSize in bytes
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmBaseAddr+mmArea.mmAreaSize):
                return mmArea
        return None
    def mmGetRealAddr(self, long mmAddr, int segId):
        if (segId and not hasattr(self.main, 'cpu')):
            self.main.exitError("mmGetRealAddr: segId != 0 && no attr 'cpu' in self.main")
        if (segId):
            if (self.main.cpu.registers.segmentOverridePrefix):
                segId = self.main.cpu.registers.segmentOverridePrefix
            mmAddr = self.main.cpu.registers.segments.getRealAddr(segId, mmAddr)
        return mmAddr
    def mmPhyRead(self, long mmAddr, long dataSize): # dataSize in bytes
        mmArea = self.mmGetArea(mmAddr, dataSize)
        if (not mmArea):
            self.main.exitError("mmPhyRead: mmArea not found! (mmAddr: {0:08x}, dataSize: {1:d})", mmAddr, dataSize)
        return mmArea.mmAreaRead(mmAddr, dataSize)
    def mmRead(self, long mmAddr, long dataSize, int segId=registers.CPU_SEGMENT_DS): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId)
        return self.mmPhyRead(mmAddr, dataSize)
    def mmPhyWrite(self, long mmAddr, data, long dataSize): # dataSize in bytes
        mmArea = self.mmGetArea(mmAddr, dataSize)
        if (not mmArea):
            self.main.exitError("mmPhyWrite: mmArea not found! (mmAddr: {0:08x}, dataSize: {1:d})", mmAddr, dataSize)
        return mmArea.mmAreaWrite(mmAddr, data, dataSize)
    def mmWrite(self, long mmAddr, data, long dataSize, int segId=registers.CPU_SEGMENT_DS): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId)
        return self.mmPhyWrite(mmAddr, data, dataSize)
    


