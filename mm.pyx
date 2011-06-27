
class MmArea:
    def __init__(self, mmBaseAddr, mmAreaSize):
        self.mmBaseAddr = mmBaseAddr
        self.mmAreaSize = mmAreaSize
        self.mmAreaData = bytearray(self.mmAreaSize)
    def mmAreaRead(self, mmPhyAddr, dataSize):
        mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        return self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize]
    def mmAreaWrite(self, mmPhyAddr, dataSize, data):
        mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize] = data
        return dataSize
    


class Mm:
    def __init__(self, main):
        self.main = main
        self.mmAreas = []
    def mmAddArea(self, mmBaseAddr, mmAreaSize):
        self.mmAreas.append(MmArea(mmBaseAddr, mmAreaSize))
    def mmDelArea(self, mmBaseAddr):
        for i in range(len(self.mmAreas)):
            if (mmBaseAddr == self.mmAreas[i].mmBaseAddr):
                del self.mmAreas[i]
                return True
        return False
    def mmGetArea(self, mmAddr, dataSize):
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize < mmArea.mmBaseAddr+mmArea.mmAreaSize):
                return mmArea
        return None
    def mmRead(self, mmAddr, dataSize):
        mmArea = self.mmGetArea(mmAddr, dataSize)
        return mmArea.mmAreaRead(mmAddr, dataSize)
    def mmWrite(self, mmAddr, dataSize, data):
        mmArea = self.mmGetArea(mmAddr, dataSize)
        return mmArea.mmAreaWrite(mmAddr, dataSize, data)
    


