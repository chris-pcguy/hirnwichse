
class MmArea:
    def __init__(self, long mmBaseAddr, long mmAreaSize):
        self.mmBaseAddr = mmBaseAddr
        self.mmAreaSize = mmAreaSize
        self.mmAreaData = bytearray(self.mmAreaSize)
    def mmAreaRead(self, long mmPhyAddr, long dataSize):
        cdef long mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        return self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize]
    def mmAreaWrite(self, long mmPhyAddr, data, long dataSize):
        cdef long mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize] = data
        return dataSize



class Mm:
    def __init__(self, main):
        self.main = main
        self.mmAreas = []
    def mmAddArea(self, long mmBaseAddr, long mmAreaSize):
        self.mmAreas.append(MmArea(mmBaseAddr, mmAreaSize))
    def mmDelArea(self, long mmBaseAddr):
        for i in range(len(self.mmAreas)):
            if (mmBaseAddr == self.mmAreas[i].mmBaseAddr):
                del self.mmAreas[i]
                return True
        return False
    def mmGetArea(self, long mmAddr, long dataSize):
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmBaseAddr+mmArea.mmAreaSize):
                return mmArea
        return None
    def mmRead(self, long mmAddr, long dataSize):
        mmArea = self.mmGetArea(mmAddr, dataSize)
        if (not mmArea):
            self.main.exitError("mmRead: mmArea not found! (mmAddr: {0:08x}, dataSize: {1:d})", mmAddr, dataSize)
        return mmArea.mmAreaRead(mmAddr, dataSize)
    def mmWrite(self, long mmAddr, data, long dataSize):
        mmArea = self.mmGetArea(mmAddr, dataSize)
        if (not mmArea):
            self.main.exitError("mmWrite: mmArea not found! (mmAddr: {0:08x}, dataSize: {1:d})", mmAddr, dataSize)
        return mmArea.mmAreaWrite(mmAddr, data, dataSize)
    


