import registers, misc

##cimport numpy
##import  numpy

cdef class MmArea:
    def __init__(self, object mm, long mmBaseAddr, long mmAreaSize):
        self.mm = mm
        self.main = self.mm.main
        self.mmBaseAddr = mmBaseAddr
        self.mmAreaSize = mmAreaSize
        self.mmAreaData = bytearray(self.mmAreaSize)
        ##self.mmAreaData = numpy.zeros(self.mmAreaSize, dtype=numpy.bytes_, order='C')
    cpdef mmAreaRead(self, long mmPhyAddr, long dataSize):
        cdef long mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        return self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize]
    cpdef mmAreaWrite(self, long mmPhyAddr, bytes data, long dataSize, int signed=False): # dataSize in bytes; use 'signed' only if writing 'int'
        cdef long mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        cdef long realDataSize = 0
        ###if (isinstance(data, int)):
        ###    data = data.to_bytes(length=dataSize, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=signed)
        realDataSize = len(data)
        if (realDataSize != dataSize):
            self.main.exitError("tried write to {0:#x} with invalid dataSize. (realDataSize: {1:d}, wrongDataSize: {2:d})", mmPhyAddr, realDataSize, dataSize)
            return 0
        self.mmAreaData[mmAreaAddr:mmAreaAddr+dataSize] = data
        return dataSize



cdef class Mm:
    def __init__(self, object main):
        self.main = main
        self.mmAreas = []
    cpdef mmAddArea(self, long mmBaseAddr, long mmAreaSize):
        self.mmAreas.append(MmArea(self, mmBaseAddr, mmAreaSize))
    cpdef mmDelArea(self, long mmBaseAddr):
        for i in range(len(self.mmAreas)):
            if (mmBaseAddr == self.mmAreas[i].mmBaseAddr):
                del self.mmAreas[i]
                return True
        return False
    cpdef mmGetArea(self, long mmAddr, long dataSize): # dataSize in bytes
        for mmArea in self.mmAreas:
            if (mmAddr >= mmArea.mmBaseAddr and mmAddr+dataSize <= mmArea.mmBaseAddr+mmArea.mmAreaSize):
                return mmArea
        return None
    cpdef mmGetRealAddr(self, long mmAddr, int segId):
        if (segId and not hasattr(self.main, 'cpu')):
            self.main.exitError("mmGetRealAddr: segId != 0 && no attr 'cpu' in self.main")
        if (segId):
            if (self.main.cpu.registers.segmentOverridePrefix):
                segId = self.main.cpu.registers.segmentOverridePrefix
            mmAddr = self.main.cpu.registers.segments.getRealAddr(segId, mmAddr)
        return mmAddr
    cpdef mmPhyRead(self, long mmAddr, long dataSize): # dataSize in bytes
        mmArea = self.mmGetArea(mmAddr, dataSize)
        if (not mmArea):
            self.main.exitError("mmPhyRead: mmArea not found! (mmAddr: {0:08x}, dataSize: {1:d})", mmAddr, dataSize)
        return mmArea.mmAreaRead(mmAddr, dataSize)
    cpdef mmRead(self, long mmAddr, long dataSize, int segId=registers.CPU_SEGMENT_DS): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId)
        return self.mmPhyRead(mmAddr, dataSize)
    cpdef mmPhyWrite(self, long mmAddr, bytes data, long dataSize): # dataSize in bytes
        mmArea = self.mmGetArea(mmAddr, dataSize)
        if (not mmArea):
            self.main.exitError("mmPhyWrite: mmArea not found! (mmAddr: {0:08x}, dataSize: {1:d})", mmAddr, dataSize)
        return mmArea.mmAreaWrite(mmAddr, data, dataSize)
    cpdef mmWrite(self, long mmAddr, bytes data, long dataSize, int segId=registers.CPU_SEGMENT_DS): # dataSize in bytes
        mmAddr = self.mmGetRealAddr(mmAddr, segId)
        return self.mmPhyWrite(mmAddr, data, dataSize)
    cpdef mmWriteValue(self, long mmAddr, long data, long dataSize, int segId=registers.CPU_SEGMENT_DS, int signed=False): # dataSize in bytes
        bytesData = data.to_bytes(length=dataSize, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=signed)
        return self.mmWrite(mmAddr, bytesData, dataSize)
    


